variable "secret_config" {
  description = "The secret config hash"
  type = "map"
}

variable "role" {
  description = "The role to grant secret access to"
}

variable "keys" {
  description = "The secret keys to allow access for"
  type = "list"
}

locals {
  ssm_secrets = "${lookup(var.secret_config, "type") == "ssm" ? 1 : 0}"
  s3_secrets = "${lookup(var.secret_config, "type") == "s3" ? 1 : 0}"
  // Remove excess slashes, and ensure leading/trailing slash so we can easily sub in the
  // arn even when blank
  raw_path_prefix = "${lookup(var.secret_config, "prefix", "")}"
  clean_path_prefix = "${join("/", compact(split("/", trimspace(local.raw_path_prefix))))}"
  path_prefix = "${length(local.clean_path_prefix) > 0 ? "/" : ""}${local.clean_path_prefix}"
  bucket = "${lookup(var.secret_config, "bucket", "")}"
}

data "template_file" "secret-access-policy-s3" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": ${jsonencode(formatlist("arn:aws:s3:::${local.bucket}${local.path_prefix}/%s", var.keys))}
    }
  ]
}
EOF
}

data "template_file" "secret-access-policy-ssm" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeParameters",
        "ssm:GetParameter*"
      ],
      "Resource": ${jsonencode(formatlist("arn:aws:ssm:::parameter${local.path_prefix}/%s", var.keys))}
    }
  ]
}
EOF
}

data "template_file" "secret-access-policy" {
  template = "${
    local.ssm_secrets ? data.template_file.secret-access-policy-ssm.rendered : (
      local.s3_secrets ? data.template_file.secret-access-policy-s3.rendered : ""
    )
  }"
}

resource "aws_iam_role_policy" "secret-access" {
  name = "secret-access"
  role = "${var.role}"

  policy = "${data.template_file.secret-access-policy.rendered}"
}
