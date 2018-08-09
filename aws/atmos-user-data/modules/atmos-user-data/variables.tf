variable "atmos_env" {
  description = "The atmos environment"
}

variable "global_name_prefix" {
  description = <<-EOF
    The global name prefix for disambiguating resource names that have a global
    scope (e.g. s3 bucket names)
  EOF
  default = ""
}

variable "local_name_prefix" {
  description = <<-EOF
    The local name prefix for disambiguating resource names that have a local scope
    (e.g. when running multiple environments in the same account)
  EOF
  default = ""
}

variable "name" {
  description = "The component name"
}

variable "account_ids" {
  description = "AWS account ids"
  type = "map"
}

variable "ops_env" {
  description = "The name of the ops environment"
  default = "ops"
}

variable "user_data" {
  description = "Additional user data script run at the end of the user data process, can also use cloudinit_files for more control"
  default = ""
}

variable "cloudinit_files" {
  description = "Additional user data files in the form needed by the cloudinit-files module (list of maps of path/content/owner/permissions)"
  type = "list"
  default = []
}

variable "cloudinit_config" {
  description = "Additional cloudinit config"
  default = ""
}

variable "instance_role" {
  description = "The instance role for adding policies required by the scripts being run as user data"
  default = ""
}

variable "policies" {
  description = "A list of policies to add to the instance role (list of maps with name, policy keys)"
  type = "list"
  default = []
}

variable "environment" {
  description = "Additional environment variables to set in the remote environment"
  type = "map"
  default = {}
}

variable "upgrade_packages" {
  description = "Set the flag to cloudinit to enable package upgrades on first boot"
  default = 1
}

variable "debug_user_data" {
  description = "Enables more verbose logging of user data scripts"
  default = 0
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default = ""
}

variable "iam_inspect_role" {
  description = "The role to use"
}

variable "iam_permission_groups" {
  description = "The groups that grant the given permissions"
  type = "map"
}

variable "zone_id" {
  description = "The route53 zone for registering each instance's hostname"
}

variable "use_public_ip" {
  description = "Use the public ip when registering instances with the route53 zone"
  default = false
}

variable "lock_table" {
  description = "The dynamodb lock table used to ensure unique hostnames"
}

variable "lock_key" {
  description = "The hash key in lock_table for creating the lock"
}

variable "user_data_bucket" {
  description = "The bucket to use for storing user_data instead of directly in instance metadata"
  default = ""
}

variable "user_data_bucket_compress" {
  description = "Compress and base64encode the user data before storing in the s3 bucket"
  default = true
}

variable "user_data_bucket_recreate_instances_on_update" {
  description = "Set true to force instance recreation on a user-data content change when using the user data bucket"
  default = true
}
