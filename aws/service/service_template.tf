<%- if use_rds -%>
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

  source_security_group = "${module.service-<%= name %>.security_group_id}"

  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"
}

<%- end -%>

<%- if use_lb -%>
module "service-<%= name %>-alb" {
  source = "../modules/alb"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "<%= name %>"

  internal = <%= ! external_lb %>
  listener_cidr = "<%= external_lb ? '0.0.0.0/0' : '${var.vpc_cidr}' %>"
  zone_id = "${module.dns.<%= external_lb ? 'public' : 'private' %>_zone_id}"
  subnet_ids = "${module.vpc.<%= external_lb ? 'public' : 'private' %>_subnet_ids}"
  vpc_id = "${module.vpc.vpc_id}"
  logs_bucket = "${aws_s3_bucket.logs.bucket}"

  <%- if cluster_ec2_backed -%>
  target_type = "instance"
  destination_port = 32768
  destination_port_to = 61000
  <%- end -%>

  destination_security_group = "${module.service-<%= name %>.security_group_id}"
  alb_certificate_arn = "${module.wildcart-cert.certificate_arn}"

  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"
}

<%- end -%>

<%- if external_lb -%>
// TODO: make alb module setup private dns entry when external service
resource "aws_route53_record" "service-<%= name %>-alb-internal" {
  zone_id = "${module.dns.private_zone_id}"
  name = "<%= name %>"
  type = "A"

  alias {
    name = "${module.service-<%= name %>-alb.lb_dns_name}"
    zone_id = "${module.service-<%= name %>-alb.lb_zone_id}"
    evaluate_target_health = true
  }
}
<%- end -%>

// Note: If you use the environment section to pass secrets directly into the
// ECS service, they will be visible in the AWS ECS Console.  To be more secure,
// you should store a secret with "atmos -e <env> secret set <key> <value>" then
// reference it inside your docker image with something like:
// https://github.com/simplygenius/atmos-example-app/blob/master/docker-entrypoint.sh
//
module "service-<%= name %>" {
  source = "../modules/ecs-service"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  region = "${var.region}"

  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnet_ids}"
  // The default security groups allow outbound to internet which is required for
  // pulling docker image from ECR
  security_groups = ["${module.vpc.security_group_ids}"]
  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"

  name = "<%= name %>"
  ecs_cluster_arn = "${aws_ecs_cluster.<%= cluster_name %>.arn}"
  <%- if cluster_ec2_backed -%>
  launch_type = "EC2"
  network_mode = "bridge"
  <%- end -%>

  integrate_with_lb = <%= use_lb ? 1 : 0 %>
  <%- if use_lb -%>
  alb_target_group_id = "${module.service-<%= name %>-alb.lb_target_group_id}"
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
<% if use_rds %>
            { "name" : "DB_HOST", "value" : "${module.service-<%= name %>-rds.hostname}" },
            { "name" : "DB_PORT", "value" : "${module.service-<%= name %>-rds.port}" },
            { "name" : "DB_NAME", "value" : "${module.service-<%= name %>-rds.database}" },
            { "name" : "DB_USER", "value" : "${module.service-<%= name %>-rds.username}" },
            { "name" : "ATMOS_SECRET_BUCKET", "value" : "${lookup(var.secret, "bucket")}" },
            { "name" : "ATMOS_SECRET_KEYS", "value" : "DB_PASS=service_<%= name %>_db_password" },

<% end %>
            { "name" : "SVC_ENV", "value" : "${var.atmos_env}" },
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
