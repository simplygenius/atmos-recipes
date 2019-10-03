resource "aws_security_group" "default" {
  name   = "${var.local_name_prefix}ecs-${var.name}"
  vpc_id = var.vpc_id
}

resource "aws_iam_role" "ecs-task" {
  name               = "${var.local_name_prefix}ecs-task-${var.name}"
  assume_role_policy = <<POLICY
{
"Version": "2008-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "ecs-tasks.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }
]
}
POLICY

}

resource "aws_iam_role" "ecs-execution" {
  name               = "${var.local_name_prefix}ecs-execution-${var.name}"
  assume_role_policy = <<POLICY
{
"Version": "2008-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "ecs-tasks.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }
]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "ecs-execution" {
  role       = aws_iam_role.ecs-execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecr_repository" "main" {
  count = signum(var.create_repository)
  name  = "${var.local_name_prefix}${var.name}"
}

resource "aws_ecr_lifecycle_policy" "main" {
  count      = signum(var.create_repository) == 1 && signum(var.image_expiry_count) == 1 ? 1 : 0
  repository = aws_ecr_repository.main[0].name

  policy = <<EOF
{
  "rules": [
      {
        "rulePriority": 1,
        "description": "Only keep the ${var.image_expiry_count} most recent images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": ${var.image_expiry_count}
        },
        "action": {
          "type": "expire"
        }
      }
  ]
}
EOF

}

resource "aws_cloudwatch_log_group" "main" {
  name              = "${var.local_name_prefix}${var.name}"
  retention_in_days = 30
}

data "template_file" "containers_template" {
  template = var.containers_template

  vars = {
    atmos_env       = var.atmos_env
    name            = "${var.local_name_prefix}${var.name}"
    cluster_name    = element(split("/", var.ecs_cluster_arn), 1)
    registry_host   = "${join("", aws_ecr_repository.main.*.registry_id)}.dkr.ecr.${var.region}.amazonaws.com"
    repository_name = join("", aws_ecr_repository.main.*.name)
    log_group_name  = aws_cloudwatch_log_group.main.name
    port            = var.port
    cpu             = var.cpu
    memory          = var.memory
  }
}

resource "aws_ecs_task_definition" "main" {
  family                = "${var.local_name_prefix}${var.name}"
  container_definitions = data.template_file.containers_template.rendered
  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }
    }
  }

  task_role_arn      = aws_iam_role.ecs-task.arn
  execution_role_arn = aws_iam_role.ecs-execution.arn

  cpu    = var.cpu
  memory = var.memory

  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type]
}

data "aws_ecs_task_definition" "main" {
  depends_on      = [aws_ecs_task_definition.main]
  task_definition = aws_ecs_task_definition.main.family
}

locals {
  lb = signum(var.integrate_with_lb) == 1
  nc = var.network_mode == "awsvpc"

}

resource "aws_ecs_service" "without_autoscale" {
  count = var.autoscaling ? 0 : 1

  name = "${var.local_name_prefix}${var.name}"

  launch_type = var.launch_type
  cluster     = var.ecs_cluster_arn

  desired_count                      = var.container_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.main.family}:${max(
    aws_ecs_task_definition.main.revision,
    data.aws_ecs_task_definition.main.revision,
  )}"

  dynamic "load_balancer" {
    for_each = local.lb ? [var.alb_target_group_id] : []
    content {
      target_group_arn = load_balancer.value
      container_name   = "${var.local_name_prefix}${var.name}"
      container_port   = var.port
    }
  }

  dynamic "network_configuration" {
    for_each = local.nc ? [1] : []
    content {
      security_groups = flatten([aws_security_group.default.id, var.security_groups])
      subnets         = var.subnet_ids
    }
  }
}

resource "aws_ecs_service" "with_autoscale" {
  count = var.autoscaling ? 1 : 0

  name = "${var.local_name_prefix}${var.name}"

  launch_type = var.launch_type
  cluster     = var.ecs_cluster_arn

  desired_count                      = var.container_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.main.family}:${max(
    aws_ecs_task_definition.main.revision,
    data.aws_ecs_task_definition.main.revision,
  )}"

  dynamic "load_balancer" {
    for_each = local.lb ? [1] : []
    content {
      target_group_arn = var.alb_target_group_id
      container_name   = "${var.local_name_prefix}${var.name}"
      container_port   = var.port
    }
  }

  dynamic "network_configuration" {
    for_each = local.nc ? [1] : []
    content {
      security_groups = flatten([aws_security_group.default.id, var.security_groups])
      subnets         = var.subnet_ids
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
