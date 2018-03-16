
variable "domain" {
  description = "The primary domain name for your organization"
}

variable "ops_email" {
  description = "The email address for receiving ops related emails"
  default = ""
}

variable "az_count" {
  description = "The number of AZs to use for redundancy"
  default = 2
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default = "10.10.0.0/16"
}

variable "permissive_external_egress" {
  description = <<-EOF
    Sets up the default security group to allow permissive external egress.
    Its safe and usually desired to leave this on (e.g. to allow an instance
    to reach out to the internet to download packages, etc), and rely on
    ingress rules for preventing internal communication if desired.
  EOF
  default = 1
}

variable "permissive_internal_ingress" {
  description = <<-EOF
    Sets up the default security group to allow permissive internal access,
    that is, all resources that have the default security group will allow
    access on any port/protocol from any other resource that also has the
    default security group. Its a good idea to leave this off and setup
    security group rules for ingress on a case by case basis (e.g. instance ->
    rds).  However, it does come in handy for debugging
  EOF
  default = 0
}

locals {
  logs_bucket = "${var.global_name_prefix}logs"
  backup_bucket = "${var.global_name_prefix}backup"
}

module "vpc" {
  source = "../modules/vpc"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  account_ids = "${var.account_ids}"

  domain = "${var.domain}"
  az_count = "${var.az_count}"
  vpc_cidr = "${var.vpc_cidr}"
}

// This allows all instances to reach out to anywhere
resource "aws_security_group_rule" "permissive-egress" {
  count = "${signum(var.permissive_external_egress)}"
  security_group_id = "${module.vpc.default_security_group_id}"

  type = "egress"
  protocol = "-1"
  from_port = 0
  to_port = 0

  cidr_blocks     = ["0.0.0.0/0"]
}

// This allows all instances to be connected to from all other instances
// internal to the vpc
resource "aws_security_group_rule" "permissive-internal-ingress" {
  count = "${signum(var.permissive_internal_ingress)}"
  security_group_id = "${module.vpc.default_security_group_id}"

  type = "ingress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  self = true
}


// Use the AWS console to subscribe an email address to this alert
resource "aws_sns_topic" "cloudwatch-alerts" {
  name = "${var.local_name_prefix}ops-alerts"
  display_name = "Ops Alerts"
}

data "template_file" "policy-logs-bucket" {
  vars {
    bucket = "${local.logs_bucket}"
    account_id = "${var.account_ids[var.atmos_env]}"
  }

  template = "${file("../templates/policy-logs-bucket.tmpl.json")}"
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.logs_bucket}"
  acl = "log-delivery-write"
  force_destroy = "${var.force_destroy_buckets}"

  lifecycle_rule {
    prefix = ""
    enabled = true

    expiration {
      days = 60
    }
  }

  // ELB: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
  policy = "${data.template_file.policy-logs-bucket.rendered}"
}

resource "aws_s3_bucket" "backup" {
  bucket = "${local.backup_bucket}"
  acl = "private"
  force_destroy = "${var.force_destroy_buckets}"
}
