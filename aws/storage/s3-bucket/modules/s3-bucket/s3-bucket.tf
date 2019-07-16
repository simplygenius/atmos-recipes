
locals {
  bucket_name = "${var.global_name_prefix}${var.name}"
  bucket_arn = "arn:aws:s3:::${local.bucket_name}"
  kms_enabled = "${var.enforce_encryption == "kms" ? 1 : 0}"
  aes_enabled = "${var.enforce_encryption == "aes" ? 1 : 0}"
  bucket_policy_default = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    $${enforce_encryption_statements}
  ]
}
EOF
  bucket_policy_maybe= "${local.kms_enabled || local.aes_enabled ? local.bucket_policy_default : ""}"
  bucket_policy = "${var.bucket_policy_template != "" ? var.bucket_policy_template : local.bucket_policy_maybe}"
  logging_config = {
    target_bucket = "${var.logs_bucket}"
    target_prefix = "s3-access-logs/"
  }
  logging = "${slice(list(local.logging_config), 0, var.logs_bucket == "" ? 0 : 1)}"
}

data "template_file" "bucket-policy" {
  template = "${local.bucket_policy}"

  vars {
    bucket_arn = "${local.bucket_arn}"
    enforce_encryption_statements = "${join("", data.template_file.bucket-policy-aes-enforcement.*.rendered)}${join("", data.template_file.bucket-policy-kms-enforcement.*.rendered)}"
  }
}

data "template_file" "bucket-policy-kms-enforcement" {
  count = "${local.kms_enabled}"

  template = <<POLICY
    {
      "Sid": "DenyIncorrectEncryptionHeader",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "${local.bucket_arn}/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    },
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "${local.bucket_arn}/*",
      "Condition": {
        "Null": {
          "s3:x-amz-server-side-encryption": "true"
        }
      }
    }
POLICY
}

data "template_file" "bucket-policy-aes-enforcement" {
  count = "${local.aes_enabled}"

  template = <<POLICY
    {
      "Sid": "DenyIncorrectEncryptionHeader",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "${local.bucket_arn}/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "${local.bucket_arn}/*",
      "Condition": {
        "Null": {
          "s3:x-amz-server-side-encryption": "true"
        }
      }
    }
POLICY
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "${local.bucket_name}"
  acl           = "${var.acl}"
  force_destroy = "${var.force_destroy_buckets}"

  logging = "${local.logging}"

  tags = "${merge(
    map(
      "Name", "${local.bucket_name}",
      "Env", "${var.atmos_env}",
      "Description", "Application Bucket for ${var.name}",
      "Source", "atmos"
    ),
    var.tags
  )}"

  versioning {
    enabled = "${var.versioning}"
  }

  lifecycle_rule {
    prefix = ""
    enabled = "${var.versioning}"

    noncurrent_version_transition = {
      storage_class = "STANDARD_IA"
      days = "${var.versioning_transition_days}"
    }
    noncurrent_version_expiration = {
      days = "${var.versioning_expiration_days}"
    }
  }

  policy = "${data.template_file.bucket-policy.rendered}"
}
