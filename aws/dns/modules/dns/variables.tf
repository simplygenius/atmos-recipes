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

variable "vpc_id" {
  description = "The VPC id"
}

variable "domain" {
  description = "The primary domain name"
}

variable "force_destroy" {
  description = "Force destroy zones, even if they have some data"
  default     = false
}

