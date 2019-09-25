data "template_file" "policy-allow-assume-service-role-cloudtrail" {
  vars = {
    service = "cloudtrail.amazonaws.com"
  }

  template = file("../templates/policy-allow-assume-service-role.tmpl.json")
}

resource "aws_iam_role" "audit-log" {
  name               = "${var.local_name_prefix}audit-log"
  assume_role_policy = data.template_file.policy-allow-assume-service-role-cloudtrail.rendered
}

data "template_file" "policy-allow-cloudtrail" {
  vars = {
    resource = "${replace(aws_cloudwatch_log_group.audit-log.arn, ":*", "")}:log-stream:${var.account_ids[var.atmos_env]}_CloudTrail_${var.region}*"
  }

  template = file("../templates/policy-allow-cloudtrail.tmpl.json")
}

resource "aws_iam_role_policy" "audit-log" {
  name = "audit-log"
  role = aws_iam_role.audit-log.name

  policy = data.template_file.policy-allow-cloudtrail.rendered
}

resource "aws_cloudwatch_log_group" "audit-log" {
  name              = "${var.local_name_prefix}audit-log"
  retention_in_days = 90
}

resource "aws_s3_bucket" "audit-log" {
  bucket        = "${var.global_name_prefix}logs-audit"
  acl           = "log-delivery-write"
  force_destroy = var.force_destroy_buckets

  lifecycle_rule {
    prefix  = ""
    enabled = true

    expiration {
      days = 60
    }
  }
}

data "template_file" "policy-allow-s3-cloudtrail" {
  vars = {
    bucket  = aws_s3_bucket.audit-log.bucket
    account = var.account_ids[var.atmos_env]
  }

  template = file("../templates/policy-allow-s3-cloudtrail.tmpl.json")
}

resource "aws_s3_bucket_policy" "audit-log" {
  bucket = aws_s3_bucket.audit-log.id
  policy = data.template_file.policy-allow-s3-cloudtrail.rendered
}

resource "aws_cloudtrail" "audit-log" {
  depends_on = [aws_s3_bucket_policy.audit-log]

  name                       = "${var.local_name_prefix}audit-log"
  s3_bucket_name             = aws_s3_bucket.audit-log.bucket
  s3_key_prefix              = "cloudtrail"
  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.audit-log.arn
  cloud_watch_logs_role_arn  = aws_iam_role.audit-log.arn
}

