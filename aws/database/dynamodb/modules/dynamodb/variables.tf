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
  type        = map(string)
}

variable "region" {
  description = "The aws region"
}

variable "name" {
  description = "The component name"
}

variable "vpc_id" {
  description = "VPC for efs"
}

variable "subnet_ids" {
  description = "The subnet ids"
  type        = list(string)
}

variable "security_groups" {
  description = "Additional security groups"
  type        = list(string)
  default     = []
}

