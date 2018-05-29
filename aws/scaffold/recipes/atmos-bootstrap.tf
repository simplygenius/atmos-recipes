// This file should be kept as minimal as possible - basically just enough for
// terraform to run, and so usually just contains the state storage, secret
// storage, lock table, and cross-account access role

data "template_file" "policy-backend-bucket" {
  vars {
    bucket = "${lookup(var.backend, "bucket")}"
  }

  template = "${file("../templates/policy-backend-bucket.tmpl.json")}"
}

resource "aws_s3_bucket" "backend" {
  bucket = "${lookup(var.backend, "bucket")}"
  acl = "private"
  force_destroy = "${var.force_destroy_buckets}"

  versioning {
    enabled = true
  }

  policy = "${data.template_file.policy-backend-bucket.rendered}"

  tags {
    Env = "${var.atmos_env}"
    Source = "atmos"
  }
}

data "template_file" "policy-secret-bucket" {
  vars {
    bucket = "${lookup(var.secret, "bucket")}"
  }

  template = "${file("../templates/policy-secret-bucket.tmpl.json")}"
}

// We want secret storage setup in bootstrap so that immediately after
// bootstrap, we can apply a full environment that may have secrets
resource "aws_s3_bucket" "secret" {
  bucket = "${lookup(var.secret, "bucket")}"
  acl = "private"
  force_destroy = "${var.force_destroy_buckets}"

  versioning {
    enabled = true
  }

  policy = "${data.template_file.policy-secret-bucket.rendered}"

  tags {
    Env = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_dynamodb_table" "backend-lock-table" {
  name = "${lookup(var.backend, "dynamodb_table")}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Env = "${var.atmos_env}"
    Source = "atmos"
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

  assume_role_policy = "${data.template_file.policy-assume-env-role.rendered}"
}

resource "aws_iam_role_policy" "env-admin" {
  name = "${var.atmos_env}-admin"
  role = "${aws_iam_role.env-admin.name}"

  policy = "${file("../templates/policy-allow-all.json")}"
}
