module "user-data-helpers" {
  source = "../../modules/atmos-user-data-helpers"

  atmos_env          = var.atmos_env
  global_name_prefix = var.global_name_prefix
  local_name_prefix  = var.local_name_prefix
  name               = var.name
  account_ids        = var.account_ids
  ops_env            = var.ops_env

  cloudwatch_alarm_target = var.cloudwatch_alarm_target
  iam_inspect_role        = var.iam_inspect_role
  iam_permission_groups   = var.iam_permission_groups
  zone_id                 = var.zone_id
  use_public_ip           = var.use_public_ip
  lock_table              = var.lock_table
  lock_key                = var.lock_key
}

module "user-data-framework" {
  source = "../../modules/atmos-user-data-framework"

  atmos_env          = var.atmos_env
  global_name_prefix = var.global_name_prefix
  local_name_prefix  = var.local_name_prefix
  name               = var.name

  upgrade_packages        = var.upgrade_packages
  debug_user_data         = var.debug_user_data
  cloudwatch_alarm_target = var.cloudwatch_alarm_target

  additional_environment      = merge(module.user-data-helpers.environment, var.environment)
  cloudinit_config            = module.user-data-helpers.config
  additional_cloudinit_config = var.cloudinit_config
  additional_user_data_files  = concat(module.user-data-helpers.files, var.cloudinit_files)

  additional_user_data = var.user_data
}

locals {
  policies     = concat(module.user-data-helpers.policies, var.policies)
  policy_count = module.user-data-helpers.policy_count + length(var.policies)
}

resource "aws_iam_role_policy" "policies" {
  count = local.policy_count

  role   = var.instance_role
  name   = local.policies[count.index]["name"]
  policy = local.policies[count.index]["policy"]
}

locals {
  user_data_bucket_enablement = var.user_data_bucket == "" ? 0 : 1
  user_data_key               = "user-data/${var.local_name_prefix}${var.name}/data.bin"
  user_data_pkg               = var.user_data_bucket_compress ? base64gzip(module.user-data-framework.rendered) : base64encode(module.user-data-framework.rendered)
  maybe_recreate_param        = var.user_data_bucket_recreate_instances_on_update ? format("?%s", md5(local.user_data_pkg)) : ""
  user_data_url               = "https://${var.user_data_bucket}.s3.amazonaws.com/${local.user_data_key}${local.maybe_recreate_param}"
}

resource "aws_s3_bucket_object" "user-data-bucket" {
  count = local.user_data_bucket_enablement

  bucket         = var.user_data_bucket
  key            = local.user_data_key
  content_base64 = local.user_data_pkg
}

data "template_cloudinit_config" "user-data-bucket" {
  count = local.user_data_bucket_enablement

  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-include-url"
    content      = local.user_data_url
  }
}

