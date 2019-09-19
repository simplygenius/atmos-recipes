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
  count = "${lookup(var.secret, "type") == "s3" ? 1 : 0}"

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

// Create the cross acccount role structure for admin
module "admin" {
  source = "../modules/cross-account-role"

  name = "${var.org_prefix}admin"
  upstream_key = "ops"
  downstream_keys = "${keys(var.account_ids)}"
  current_key = "${var.atmos_env}"
  account_map = "${var.account_ids}"
  downstream_role_policies = {
    "allows-all" = "${file("../templates/policy-allow-all.json")}"
  }
  require_mfa = "${var.require_mfa}"
  max_session_duration = 10800
}

// For use in remote state for atmos-permissions.tf in default working group
output "admin_groups" {
  value = "${module.admin.upstream_group_names}"
}

output "superadmin_group" {
  value = "${module.admin.upstream_aggregate_group_name}"
}

// Members of the super admin group need to be allowed to assume role to the bootstrap role name
// for each env account
data "template_file" "policy-allow-assume-env-role-for-bootstrap" {
  count = "${module.admin.in_upstream_only_count * length(var.all_env_names)}"

  vars {
    account_id = "${lookup(var.account_ids, var.all_env_names[count.index])}"
    role_name = "${var.atmos_config["auth_bootstrap_assume_role_name"]}"
  }

  template = "${file("../templates/policy-allow-assume-env-role.tmpl.json")}"
}

// Attach to the super admin group the policy for assuming each env bootstrap role
resource "aws_iam_group_policy" "ops-bootstrap-admin" {
  count = "${module.admin.in_upstream_only_count * length(var.all_env_names)}"

  name = "allow-bootstrap-assume-role-to-${module.admin.upstream_group_names[var.all_env_names[count.index]]}"
  group = "${module.admin.upstream_aggregate_group_name}"
  policy = "${data.template_file.policy-allow-assume-env-role-for-bootstrap.*.rendered[count.index]}"
}
