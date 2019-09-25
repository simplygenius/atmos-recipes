locals {
  upstream_account   = var.account_ids[var.upstream_env]
  upstream_role_name = "${var.local_name_prefix}${var.name}"

  in_upstream_env   = var.upstream_env == var.atmos_env ? 1 : 0
  in_downstream_env = var.upstream_env != var.atmos_env ? 1 : 0
}

data "null_data_source" "downstream" {
  count = length(var.downstream_envs)

  inputs = {
    account_ids = var.account_ids[element(var.downstream_envs, count.index)]
  }
}

resource "aws_iam_role" "upstream" {
  count = local.in_upstream_env

  name = local.upstream_role_name
  path = "/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          ${join(
  ",",
  formatlist(
    "\"arn:aws:iam::%s:root\"",
    data.null_data_source.downstream.*.outputs.account_ids,
  ),
)}
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

data "template_file" "upstream-policy" {
  template = var.policy
  vars = {
    upstream_account = local.upstream_account
  }
}

resource "aws_iam_role_policy" "upstream" {
  count = local.in_upstream_env

  name = local.upstream_role_name
  role = aws_iam_role.upstream[0].name

  policy = data.template_file.upstream-policy.rendered
}

data "template_file" "downstream-policy" {
  template = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::${local.upstream_account}:role/${local.upstream_role_name}"
  }
}
POLICY

}

