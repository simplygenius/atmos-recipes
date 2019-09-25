variable "atmos_env" {
  description = "The atmos environment"
}

variable "upstream_env" {
  description = "The env here the actions granted by the policy will occur"
}

variable "downstream_envs" {
  description = "The envs that need to perform actions against the upstream env"
  type        = list(string)
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
  description = "Maps atmos_envs to account numbers, value supplied by atmos runtime"
  type        = map(string)
}

variable "policy" {
  description = "The permissions against the upstream env that is granted downstream"
}

