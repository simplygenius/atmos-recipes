// Role that allows granting permissions to ecs tasks
resource "aws_iam_role" "ecs-task" {
  name = "${var.local_name_prefix}ecs-task-${var.name}"
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

// Role that allows granting permissions to ecs tasks
resource "aws_iam_role" "ecs-execution" {
  name = "${var.local_name_prefix}ecs-execution-${var.name}"
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

// Add policy for talking to alb into the role
resource "aws_iam_role_policy_attachment" "ecs-execution" {
  role = "${aws_iam_role.ecs-execution.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecr_repository" "main" {
  count = "${signum(var.create_repository)}"
  name = "${var.local_name_prefix}${var.name}"
}

resource "aws_ecr_lifecycle_policy" "main" {
  count = "${signum(var.create_repository)}"
  repository = "${aws_ecr_repository.main.name}"

  policy = <<EOF
{
  "rules": [
      {
        "rulePriority": 1,
        "description": "Expire images older than ${var.image_expiry_days} days",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": ${var.image_expiry_days}
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
  name = "${var.local_name_prefix}${var.name}"
  retention_in_days = 30
}

data "template_file" "containers_template" {
  template = "${var.containers_template}"

  vars {
    atmos_env = "${var.atmos_env}"
    name = "${var.local_name_prefix}${var.name}"
    registry_host = "${join("", aws_ecr_repository.main.*.registry_id)}.dkr.ecr.${var.region}.amazonaws.com"
    repository_name = "${join("", aws_ecr_repository.main.*.name)}"
    log_group_name = "${aws_cloudwatch_log_group.main.name}"
    port = "${var.port}"
    cpu = "${var.cpu}"
    memory = "${var.memory}"
  }
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.local_name_prefix}${var.name}"
  container_definitions = "${data.template_file.containers_template.rendered}"

  task_role_arn = "${aws_iam_role.ecs-task.arn}"
  execution_role_arn = "${aws_iam_role.ecs-execution.arn}"

  cpu = "${var.cpu}"
  memory = "${var.memory}"

  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}
