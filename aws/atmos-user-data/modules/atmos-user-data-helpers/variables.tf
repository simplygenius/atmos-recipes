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
  type        = map(string)
}

variable "ops_env" {
  description = "The name of the ops environment"
}

variable "user_data_dir" {
  description = "User data scripts"
  default     = "/opt/atmos/user_data.d"
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default     = ""
}

variable "enable_iam_user_ssh" {
  description = ""
  default     = 1
}

variable "iam_inspect_role" {
  description = "The role to use for inspecting iam in ops account to determine users"
  default     = ""
}

variable "iam_permission_groups" {
  description = "The groups that grant the given permissions - keys of account, ssh, sudo mapping to the iam groups that grant each of those"
  type        = map(string)
  default = {
    account = []
    ssh     = []
    sudo    = []
  }
}

variable "zone_id" {
  description = "The route53 zone for registering each instance's hostname"
}

variable "lock_table" {
  description = "The dynamodb lock table used to ensure unique hostnames"
}

variable "lock_key" {
  description = "The hash key in lock_table for creating the lock"
}

variable "enable_hostnames" {
  description = ""
  default     = 1
}

variable "use_public_ip" {
  description = "Use the public ip when registering instances with the route53 zone"
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = ""
  default     = 1
}

variable "cloudwatch_agent_config" {
  description = "The configuration for the cloudwatch agent on each instance.  Processed as a template with vars: global_name_prefix, local_name_prefix, atmos_env, name"
  default     = ""
}

