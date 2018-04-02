variable "atmos_env" {
  description = "The atmos atmos_env, value supplied by atmos runtime"
}

variable "account_ids" {
  description = "Maps atmos_envs to account numbers, value supplied by atmos runtime"
  type = "map"
}

variable "atmos_config" {
  description = <<-EOF
    The atmos config hash, value supplied by atmos runtime.  Convenience to allow
    retrieving atmos configuration without having to define additional variable
    resources
  EOF
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

variable "ops_admins_env" {
  description = <<-EOF
    Members of the ops admin group will also have admin access to all other
    environments
  EOF
  default = 1
}

variable "ops_alerts_topic" {
  description = "The sns topic name for ops alerts"
  default = "ops-alerts"
}

locals {
  ops_env = "ops"
  ops_account = "${lookup(var.account_ids, local.ops_env)}"
  envs_without_ops = "${compact(split(",", replace(join(",", keys(var.account_ids)), local.ops_env, "")))}"
}

provider "aws" {
  version = "1.9.0"
  region = "${var.region}"
}
