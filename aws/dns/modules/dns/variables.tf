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

variable "account_ids" {
  description = "AWS account ids"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "domain" {
  description = "The primary domain name"
}

