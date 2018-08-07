
module "user-data-helpers" {
  source = "../../modules/atmos-user-data-helpers"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "${var.name}"
  account_ids = "${var.account_ids}"
  ops_env = "${var.ops_env}"

  cloudwatch_alarm_target = "${var.cloudwatch_alarm_target}"
  iam_inspect_role = "${var.iam_inspect_role}"
  iam_permission_groups = "${var.iam_permission_groups}"
  zone_id = "${var.zone_id}"
  lock_table = "${var.lock_table}"
  lock_key = "${var.lock_key}"
}

module "user-data-framework" {
  source = "../../modules/atmos-user-data-framework"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "${var.name}"

  upgrade_packages = "${var.upgrade_packages}"
  debug_user_data = "${var.debug_user_data}"
  cloudwatch_alarm_target = "${var.cloudwatch_alarm_target}"

  additional_environment = "${merge(module.user-data-helpers.environment, var.environment)}"
  cloudinit_config = "${module.user-data-helpers.config}"
  additional_cloudinit_config = "${var.cloudinit_config}"
  additional_user_data_files = "${concat(module.user-data-helpers.files, var.cloudinit_files)}"

  additional_user_data = "${var.user_data}"
}

locals {
  policies = "${concat(module.user-data-helpers.policies, var.policies)}"
}

resource "aws_iam_role_policy" "policies" {
  count = "${length(local.policies)}"

  role = "${var.instance_role}"
  name = "${lookup(local.policies[count.index], "name")}"
  policy = "${lookup(local.policies[count.index], "policy")}"
}
