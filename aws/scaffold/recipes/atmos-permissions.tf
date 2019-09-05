// The all_env_names variable is in the order the envs show up in the yml so we
// don't end up with resource modifications innstead of creations when applying
// to a new env (modifying a resource could break access whilst in the middle
// of an apply)
resource "aws_iam_group" "env-admin" {
  count = "${var.atmos_env == local.ops_env ? length(var.all_env_names) : 0}"

  name = "${var.org_prefix}${var.all_env_names[count.index]}-admin"
  path = "/"
}

data "template_file" "policy-allow-assume-env-role" {
  count = "${var.atmos_env == local.ops_env ? length(var.all_env_names) : 0}"

  vars {
    account_id = "${lookup(var.account_ids, var.all_env_names[count.index])}"
    // don't use auth_assume_role_name as it is based on current atmos_env
    role_name = "${var.org_prefix}${var.all_env_names[count.index]}-admin"
  }

  template = "${file("../templates/policy-allow-assume-env-role.tmpl.json")}"
}

resource "aws_iam_group_policy" "env-admin" {
  count = "${var.atmos_env == local.ops_env ? length(var.all_env_names) : 0}"

  name = "allow-assume-role-to-${var.org_prefix}${var.all_env_names[count.index]}"
  group = "${aws_iam_group.env-admin.*.id[count.index]}"
  policy = "${data.template_file.policy-allow-assume-env-role.*.rendered[count.index]}"
}

// ops members need to be allowed to assume role to the bootstrap role name
// for each env account
data "template_file" "policy-allow-assume-env-role-for-bootstrap" {
  count = "${var.atmos_env == local.ops_env ? length(local.envs_without_ops) : 0}"

  vars {
    account_id = "${lookup(var.account_ids, local.envs_without_ops[count.index])}"
    role_name = "${var.atmos_config["auth_bootstrap_assume_role_name"]}"
  }

  template = "${file("../templates/policy-allow-assume-env-role.tmpl.json")}"
}

resource "aws_iam_group_policy" "ops-bootstrap-admin" {
  count = "${var.atmos_env == local.ops_env ? length(local.envs_without_ops) : 0}"

  name = "allow-bootstrap-assume-role-to-${var.org_prefix}${local.envs_without_ops[count.index]}"
  group = "${var.org_prefix}ops-admin"
  policy = "${data.template_file.policy-allow-assume-env-role-for-bootstrap.*.rendered[count.index]}"

  depends_on = ["aws_iam_group.env-admin"]
}

// A convenience to allow members of the ops admin group to also admin all
// other environments
data "template_file" "policy-allow-assume-env-role-to-env-for-ops" {
  count = "${var.atmos_env == local.ops_env ? length(local.envs_without_ops) * var.ops_admins_env : 0}"

  vars {
    account_id = "${lookup(var.account_ids, local.envs_without_ops[count.index])}"
    // don't use auth_assume_role_name as it is based on current atmos_env
    role_name = "${var.org_prefix}${local.envs_without_ops[count.index]}-admin"
  }

  template = "${file("../templates/policy-allow-assume-env-role.tmpl.json")}"
}

resource "aws_iam_group_policy" "ops-env-admin" {
  count = "${var.atmos_env == local.ops_env ? length(local.envs_without_ops) * var.ops_admins_env : 0}"

  name = "allow-assume-role-to-${var.org_prefix}${local.envs_without_ops[count.index]}-for-ops"
  group = "${var.org_prefix}ops-admin"
  policy = "${data.template_file.policy-allow-assume-env-role-to-env-for-ops.*.rendered[count.index]}"

  depends_on = ["aws_iam_group.env-admin"]
}

resource "aws_iam_group" "all-users" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "${var.org_prefix}all-users"
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

  name = "${var.org_prefix}self-management"
  group = "${aws_iam_group.all-users.name}"

  policy = "${data.template_file.policy-self-management.rendered}"
}

data "template_file" "policy-assume-env-deployer-role" {
  vars {
    ops_account = "${local.ops_account}"
    require_mfa = false
  }

  template = "${file("../templates/policy-assume-env-role.tmpl.json")}"
}

resource "aws_iam_role" "deployer" {
  name               = "${var.org_prefix}${var.atmos_env}-deployer"
  path               = "/"
  assume_role_policy = "${data.template_file.policy-assume-env-deployer-role.rendered}"
}

resource "aws_iam_user" "deployer" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "${var.org_prefix}deployer"
  path = "/"
}

data "template_file" "policy-allow-assume-env-role-for-deployer" {
  count = "${var.atmos_env == local.ops_env ? length(var.all_env_names) : 0}"

  vars {
    account_id = "${lookup(var.account_ids, var.all_env_names[count.index])}"
    // don't use auth_assume_role_name as it is based on current atmos_env
    role_name = "${var.org_prefix}${var.all_env_names[count.index]}-deployer"
  }

  template = "${file("../templates/policy-allow-assume-env-role.tmpl.json")}"
}

resource "aws_iam_user_policy" "deployer" {
  count = "${var.atmos_env == local.ops_env ? length(var.all_env_names) : 0}"

  name = "allow-assume-role-to-${var.org_prefix}${var.all_env_names[count.index]}-deployer"
  user = "${aws_iam_user.deployer.name}"

  policy = "${data.template_file.policy-allow-assume-env-role-for-deployer.*.rendered[count.index]}"
}

resource "aws_iam_access_key" "deployer" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  user = "${aws_iam_user.deployer.name}"
}

// Set enabled=1 to display deployer keys to get them for your CI system
module "display-access-keys" {
  source = "../modules/atmos-ipc"
  action = "notify"
  enabled = "${0 * (var.atmos_env == local.ops_env ? 1 : 0)}"
  params = {
    message = <<-EOF
    deployer-access-key: ${join("", aws_iam_access_key.deployer.*.id)}
    deployer-access-secret: ${join("", aws_iam_access_key.deployer.*.secret)}
    EOF
  }
}

resource "aws_iam_role_policy" "deployer" {
  name = "${var.org_prefix}${var.atmos_env}-deployer"
  role = "${aws_iam_role.deployer.name}"

  policy = "${file("../templates/policy-deployer-permissions.json")}"
}

resource "aws_iam_group_policy" "allow-billing-access" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "${var.org_prefix}allow-billing-access"
  group = "${var.org_prefix}ops-admin"

  policy = "${file("../templates/policy-allow-all-billing.json")}"
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}
