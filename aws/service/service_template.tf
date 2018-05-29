<%- if rds -%>
variable "service_<%= name %>_db_password" {
  // Should be overriden in secrets
  default = "<%= name.length >= 8 ? name : "#{name}secret!" %>"
}

module "service-<%= name %>-secret-access" {
  source = "../modules/secret-access"
  secret_bucket = "${lookup(var.secret, "bucket")}"
  role = "${module.service-<%= name %>.task_role}"
  keys = ["service_<%= name %>_db_password"]
}

module "service-<%= name %>-rds" {
  source = "../modules/rds"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "<%= name %>"

  engine = "postgres"
  engine_version = "9.6.6"
  family = "postgres9.6"

  db_name = "<%= name %>"
  db_username = "<%= name %>"
  db_password = "${var.service_<%= name %>_db_password}"

  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnet_ids}"
  zone_id = "${module.dns.private_zone_id}"

  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"
}

resource "aws_security_group_rule" "service-<%= name %>-rds-ingress" {
  security_group_id = "${module.service-<%= name %>-rds.security_group_id}"

  type = "ingress"
  from_port = "${module.service-<%= name %>-rds.port}"
  to_port = "${module.service-<%= name %>-rds.port}"
  protocol = "tcp"

  source_security_group_id = "${module.service-<%= name %>.security_group_id}"
}

<%- end -%>

<%- if lb -%>
module "service-<%= name %>-alb" {
  source = "../modules/alb"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "<%= name %>"

  internal = <%= ! external %>
  zone_id = "${module.dns.<%= external ? 'public' : 'private' %>_zone_id}"
  subnet_ids = "${module.vpc.<%= external ? 'public' : 'private' %>_subnet_ids}"
  vpc_id = "${module.vpc.vpc_id}"
  logs_bucket = "${aws_s3_bucket.logs.bucket}"

  alb_certificate_arn = "${module.wildcart-cert.certificate_arn}"

  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"
}

resource "aws_security_group_rule" "service-<%= name %>-alb-http-ingress" {
  security_group_id = "${module.service-<%= name %>-alb.security_group_id}"

  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"

  <%- if external -%>
  cidr_blocks = ["0.0.0.0/0"]
  <%- else -%>
  cidr_blocks = ["${var.vpc_cidr}"]
  <%- end -%>
}

resource "aws_security_group_rule" "service-<%= name %>-alb-https-ingress" {
  security_group_id = "${module.service-<%= name %>-alb.security_group_id}"

  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"

  <%- if external -%>
  cidr_blocks = ["0.0.0.0/0"]
  <%- else -%>
  cidr_blocks = ["${var.vpc_cidr}"]
  <%- end -%>
}

resource "aws_security_group_rule" "service-<%= name %>-alb-ecs-egress" {
  security_group_id = "${module.service-<%= name %>-alb.security_group_id}"

  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"

  source_security_group_id = "${module.service-<%= name %>.security_group_id}"
}

<%- end -%>

// TODO: private dns entry when external service or make alb module do it
//resource "aws_route53_record" "service-<%= name %>-alb-internal" {
//  zone_id = "${module.dns.private_zone_id}"
//  name = "<%= name %>"
//  type = "A"
//
//  alias {
//    name = "${module.service-<%= name %>-alb.alb_dns_name}"
//    zone_id = "${module.service-<%= name %>-alb.alb_zone_id}"
//    evaluate_target_health = true
//  }
//}

// TODO: the secrets passed into ECS service are visible in the AWS ECS
// Console.  This is not that huge a deal as everyone that has permissions to
// see the console also has permissions to access the secrets via terraform. If
// we want to change this we can make the docker entrypoint script for the ECS
// service pull the secret direct from s3 (similar to how the parity recipe
// does it), or we can encrypt the secret here using kms and decrypt it in the
// docker entrypoint script for the service

module "service-<%= name %>" {
  source = "../modules/ecs-fargate-service"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  region = "${var.region}"

  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnet_ids}"
  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"

  name = "<%= name %>"
  ecs_cluster_arn = "${aws_ecs_cluster.services.arn}"

  integrate_with_lb = <%= lb ? 1 : 0 %>
  <%- if lb -%>
  alb_target_group_id = "${module.service-<%= name %>-alb.alb_target_group_id}"
  <%- end -%>

  cpu = 256
  memory = 512

  containers_template = <<TMPL
    [
      {
        "name": "$${name}",
        "image": "$${registry_host}/$${repository_name}:latest",
        "portMappings": [
          {
            "containerPort": $${port},
            "hostPort": $${port}
          }
        ],
        "environment" : [
            { "name" : "ATMOS_ENV", "value" : "${var.atmos_env}" },
<% if rds %>
            { "name" : "DB_HOST", "value" : "${module.service-<%= name %>-rds.hostname}" },
            { "name" : "DB_PORT", "value" : "${module.service-<%= name %>-rds.port}" },
            { "name" : "DB_NAME", "value" : "${module.service-<%= name %>-rds.database}" },
            { "name" : "DB_USER", "value" : "${module.service-<%= name %>-rds.username}" },
            { "name" : "ATMOS_SECRET_BUCKET", "value" : "${lookup(var.secret, "bucket")}" },
            { "name" : "ATMOS_SECRET_KEYS", "value" : "DB_PASS=service_<%= name %>_db_password" },

<% end %>
            { "name" : "SVC_NAME", "value" : "$${name}" },
            { "name" : "SVC_PORT", "value" : "$${port}" }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "$${log_group_name}",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "$${name}"
            }
        }
      }
    ]
TMPL
}

resource "aws_security_group_rule" "service-<%= name %>-ecs-ingress" {
  security_group_id = "${module.service-<%= name %>.security_group_id}"

  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"

  source_security_group_id = "${module.service-<%= name %>-alb.security_group_id}"
}

resource "aws_security_group_rule" "service-<%= name %>-ecs-egress" {
  security_group_id = "${module.service-<%= name %>.security_group_id}"

  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
