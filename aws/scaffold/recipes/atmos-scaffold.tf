variable "atmos_env" {
  description = "The atmos atmos_env, value supplied by atmos runtime"
}

variable "account_ids" {
  description = "Maps atmos_envs to account numbers, value supplied by atmos runtime"
  type = "map"
}

variable "atmos_config" {
  description = "The atmos config hash, value supplied by atmos runtime.  Convenience to allow retrieving atmos configuration without having to define additional variable resources"
  type = "map"
}

variable "global_name_prefix" {
  description = "The prefix used to disambiguate global resource names, value supplied by atmos.yml"
}

variable "local_name_prefix" {
  description = "The prefix used to disambiguate local resource names, value supplied by atmos.yml"
}

variable "region" {
  description = "The aws region, value supplied by atmos.yml"
}

variable "backend_bucket" {
  description = "The bucket for storing backend state, value supplied by atmos.yml"
}

variable "backend_dynamodb_table" {
  description = "The dynamodb table for locking backend state, value supplied by atmos.yml"
}

variable "secret_bucket" {
  description = "The bucket for storing secrets, value supplied by atmos.yml"
}

variable "force_destroy_buckets" {
  description = <<-EOF
    Allows destruction of s3 buckets that have contents.  Set to true for
    error-free destroys, but should be false for day to day usage.  Note you
    need to apply with it set to true in order for it to take effect in a
    destroy.  e.g.
      TF_VAR_force_destroy_buckets=true atmos apply
      TF_VAR_force_destroy_buckets=true atmos destroy
  EOF
  default = false
}

locals {
  ops_env = "ops"
  ops_account = "${lookup(var.account_ids, local.ops_env)}"
}

resource "null_resource" "bootstrap-ops" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  triggers {
    state_bucket = "${aws_s3_bucket.backend.id}"
    state_lock_table = "${aws_dynamodb_table.backend-lock-table.id}"
    secret_bucket = "${aws_s3_bucket.secret.id}"
    ops_admin_groups = "${join(",", aws_iam_group_policy.env-admin.*.id)}",
    env_admin_role = "${aws_iam_role_policy.env-admin.id}"
    all_user_group = "${aws_iam_group_policy.self-management.id}"
  }
}

resource "null_resource" "bootstrap-env" {
  count = "${var.atmos_env == local.ops_env ? 0 : 1}"

  triggers {
    state_bucket = "${aws_s3_bucket.backend.id}"
    state_lock_table = "${aws_dynamodb_table.backend-lock-table.id}"
    secret_bucket = "${aws_s3_bucket.secret.id}"
    env_admin_role = "${aws_iam_role_policy.env-admin.id}"
  }
}

provider "aws" {
  version = "1.9.0"
  region = "${var.region}"
}

data "template_file" "policy-backend-bucket" {
  vars {
    bucket = "${var.backend_bucket}"
  }

  template = "${file("../templates/policy-backend-bucket.tmpl.json")}"
}

resource "aws_s3_bucket" "backend" {
  bucket = "${var.backend_bucket}"
  acl = "private"
  force_destroy = "${var.force_destroy_buckets}"

  versioning {
    enabled = true
  }

  policy = "${data.template_file.policy-backend-bucket.rendered}"

  tags {
    Env = "${var.atmos_env}"
    Source = "Atmos"
  }
}

resource "aws_dynamodb_table" "backend-lock-table" {
  name = "${var.backend_dynamodb_table}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Env = "${var.atmos_env}"
    Source = "Atmos"
  }
}

data "template_file" "policy-secret-bucket" {
  vars {
    bucket = "${var.secret_bucket}"
  }

  template = "${file("../templates/policy-backend-bucket.tmpl.json")}"
}

resource "aws_s3_bucket" "secret" {
  bucket = "${var.secret_bucket}"
  acl = "private"
  force_destroy = "${var.force_destroy_buckets}"

  versioning {
    enabled = true
  }

  policy = "${data.template_file.policy-secret-bucket.rendered}"

  tags {
    Env = "${var.atmos_env}"
    Source = "Atmos"
  }
}

data "template_file" "policy-assume-env-role" {
  vars {
    ops_account = "${local.ops_account}"
    require_mfa = true
  }

  template = "${file("../templates/policy-assume-env-role.tmpl.json")}"
}

resource "aws_iam_role" "env-admin" {
  name  = "${var.atmos_env}-admin"
  path  = "/"

//  lifecycle {
//    prevent_destroy = true
//    create_before_destroy = true
//  }

  assume_role_policy = "${data.template_file.policy-assume-env-role.rendered}"
}

resource "aws_iam_role_policy" "env-admin" {
  name = "${var.atmos_env}-admin"
  role = "${aws_iam_role.env-admin.name}"

//  lifecycle {
//    prevent_destroy = true
//    create_before_destroy = true
//  }

  policy = "${file("../templates/policy-allow-all.json")}"
}

resource "aws_iam_group" "env-admin" {
  count = "${var.atmos_env == local.ops_env ? length(var.account_ids) : 0}"

  name = "${element(keys(var.account_ids), count.index)}-admin"
  path = "/"
}

data "template_file" "policy-allow-assume-env-role" {
  count = "${var.atmos_env == local.ops_env ? length(var.account_ids) : 0}"

  vars {
    atmos_env = "${element(keys(var.account_ids), count.index)}"
    account_id = "${element(values(var.account_ids), count.index)}"
  }

  template = "${file("../templates/policy-allow-assume-env-role.tmpl.json")}"
}

resource "aws_iam_group_policy" "env-admin" {
  count = "${var.atmos_env == local.ops_env ? length(var.account_ids) : 0}"

  name = "admins-${element(keys(var.account_ids), count.index)}"
  group = "${aws_iam_group.env-admin.*.id[count.index]}"
  policy = "${data.template_file.policy-allow-assume-env-role.*.rendered[count.index]}"
}

resource "aws_iam_group" "all-users" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "all-users"
  path = "/"
}

// Users are explictily denied from doing anything but self management when they do not have an MFA token
// https://www.trek10.com/blog/improving-the-aws-force-mfa-policy-for-IAM-users/
//
data "template_file" "policy-self-management" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  vars {
    ops_account = "${local.ops_account}"
    require_mfa = true
  }

  template = "${file("../templates/policy-self-management.tmpl.json")}"
}

resource "aws_iam_group_policy" "self-management" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "self-management"
  group = "${aws_iam_group.all-users.name}"

  policy = "${data.template_file.policy-self-management.rendered}"
}
