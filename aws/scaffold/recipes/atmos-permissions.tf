// The all_env_names variable is in the order the envs show up in the yml so we
// don't end up with resource modifications innstead of creations when applying
// to a new env (modifying a resource could break access whilst in the middle
// of an apply)

// The all-users group which controls basic controls for each human
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

// Attach to the all-users group the policy for basic controls
resource "aws_iam_group_policy" "self-management" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "${var.org_prefix}self-management"
  group = "${aws_iam_group.all-users.name}"

  policy = "${data.template_file.policy-self-management.rendered}"
}

// Create the cross acccount role structure for a deployer
module "deployer" {
  source = "../modules/cross-account-role"

  name = "${var.org_prefix}deployer"
  upstream_key = "ops"
  downstream_keys = "${keys(var.account_ids)}"
  current_key = "${var.atmos_env}"
  account_map = "${var.account_ids}"
  downstream_role_policies = {
    "allows-ecs-deploy" = "${file("../templates/policy-deployer-permissions.json")}"
  }
  // deploys usually happen from CI, so mfa is not practical
  require_mfa = "false"
}

data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config {
    bucket = "${lookup(var.backend, "bucket")}"
    key = "bootstrap-terraform.tfstate"
    region = "${lookup(var.backend, "region")}"
  }
}

// Attach policy to each admin group as a convenience to allow each to the deployer role for that env
resource "aws_iam_group_policy" "admin-group-gets-each-env-deployer" {
  count = "${module.deployer.in_upstream_only_count * length(var.all_env_names)}"

  name = "allow-assume-role-to-${module.deployer.upstream_group_names[var.all_env_names[count.index]]}"
  group = "${data.terraform_remote_state.bootstrap.admin_groups[var.all_env_names[count.index]]}"
  policy = "${module.deployer.upstream_group_policies[var.all_env_names[count.index]]}"
}

// Attach policies to the super admin group as a convenience to allow ops to assume role to each env deployer
resource "aws_iam_group_policy" "superadmin-group-gets-all-env-deployer" {
  count = "${module.deployer.in_upstream_only_count * length(var.all_env_names)}"

  name = "allow-assume-role-to-${module.deployer.upstream_group_names[var.all_env_names[count.index]]}"
  group = "${data.terraform_remote_state.bootstrap.superadmin_group}"
  policy = "${module.deployer.upstream_group_policies[var.all_env_names[count.index]]}"
}

// The deployer user with deploy only access in each env - allows us to create access keys for use in CI
resource "aws_iam_user" "deployer" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "${var.org_prefix}deployer"
  path = "/"
}

// Add the deployer user to the aggregate deploy group to give them access to deploy in all envs
resource "aws_iam_group_membership" "deployer-user-in-all-deployer-groups" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "belong-to-${module.deployer.upstream_aggregate_group_name}}"
  group = "${module.deployer.upstream_aggregate_group_name}"
  users = ["${aws_iam_user.deployer.name}"]
}

resource "aws_iam_access_key" "deployer" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  user = "${aws_iam_user.deployer.name}"
}

variable "display_deployer" {
  description = "Set to 1 to display the aws keys for the deployer user, e.g. TF_VAR_display_deployer=1 atmos -e ops plan"
  default = 0
}

// Set enabled=1 to display deployer keys to get them for your CI system
module "display-access-keys" {
  source = "../modules/atmos-ipc"
  action = "notify"
  enabled = "${var.display_deployer * (var.atmos_env == local.ops_env ? 1 : 0)}"

  params = {
    inline = "true"
    message = <<-EOF
    deployer-access-key: ${join("", aws_iam_access_key.deployer.*.id)}
    deployer-access-secret: ${join("", aws_iam_access_key.deployer.*.secret)}
    EOF
  }
}

resource "aws_iam_group_policy" "allow-billing-access" {
  count = "${var.atmos_env == local.ops_env ? 1 : 0}"

  name = "${var.org_prefix}allow-billing-access"
  group = "${data.terraform_remote_state.bootstrap.superadmin_group}"

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
