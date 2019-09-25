variable "atmos_env" {
  description = "The atmos atmos_env, value supplied by atmos runtime"
}

variable "all_env_names" {
  description = <<-EOF
    All the atmos environment names in the order they appear in yml file so
    that adding environments doesn't cause transient permission breakages,
    value supplied by atmos runtime
EOF


  type = list(string)
}

variable "account_ids" {
  description = "Maps atmos_envs to account numbers, value supplied by atmos runtime"
  type        = map(string)
}

variable "atmos_working_group" {
  description = <<-EOF
    The atmos working group - independent groupings of terraform recipes within
    the same env, e.g. bootstrap, default, value supplied by atmos runtime
EOF


  type = string
}

variable "atmos_config" {
  description = <<-EOF
    The atmos config hash, value supplied by atmos runtime.  Convenience to allow
    retrieving atmos configuration without having to define additional variable
    resources
EOF


  type = map(string)
}

variable "org" {
  description = "The atmos organization, value supplied by atmos.yml"
}

variable "global_name_prefix" {
  description = "The prefix used to disambiguate global resource names, value supplied by atmos.yml"
}

variable "local_name_prefix" {
  description = "The prefix used to disambiguate local resource names, value supplied by atmos.yml"
}

variable "org_prefix" {
  description = "The prefix used to disambiguate ops resource names for multiple orgs, value supplied by atmos.yml"
}

variable "region" {
  description = "The aws region, value supplied by atmos.yml"
}

variable "backend" {
  description = "The backend state configuration, value supplied by atmos.yml"
  type        = map(string)
}

variable "secret" {
  description = "The secrets configuration, value supplied by atmos.yml"
  type        = map(string)
}

variable "logs_bucket" {
  description = "The bucket for storing logs, value supplied by atmos.yml"
}

variable "backup_bucket" {
  description = "The bucket for storing backups, value supplied by atmos.yml"
}

variable "is_dev" {
  description = "Indicates a development environment"
  default     = false
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

variable "require_mfa" {
  description = <<-EOF
    Require MFA wherever it makes sense, e.g. assuming an AWS IAM role
EOF


  default = true
}

variable "ops_alerts_topic" {
  description = "The sns topic name for ops alerts"
  default     = "ops-alerts"
}

locals {
  ops_env         = "ops"
  ops_account     = var.account_ids[local.ops_env]
  current_account = var.account_ids[var.atmos_env]
  envs_without_ops = compact(
    split(
      ",",
      replace(join(",", var.all_env_names), local.ops_env, ""),
    ),
  )
}

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.region
}
