locals {
  logs_bucket = "${var.global_name_prefix}logs"
  backup_bucket = "${var.global_name_prefix}backup"

  ops_alerts_topic_arn = "arn:aws:sns:${var.region}:${var.account_ids[var.atmos_env]}:${var.local_name_prefix}${var.ops_alerts_topic}"

  subscribe_topic_msg = <<-EOF
To receive alerts, use the AWS console to subscribe an email address to the
SNS topic:
${var.local_name_prefix}${var.ops_alerts_topic}
  EOF

  subscribe_topic_ipc = "${jsonencode(map(
    "action", "notify",
    "message", local.subscribe_topic_msg
  ))}"
}

// Use the AWS console to subscribe an email address to this alert
resource "aws_sns_topic" "ops-alerts" {
  count = "${var.ops_alerts_topic == "" ? 0 : 1}"
  name = "${var.local_name_prefix}${var.ops_alerts_topic}"
  display_name = "Ops Alerts"

  provisioner "local-exec" {
    command = "$ATMOS_IPC_CLIENT '${local.subscribe_topic_ipc}'"
    on_failure = "continue"
  }
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
