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

variable "vpc_id" {
  description = "VPC for efs"
}

variable "subnet_ids" {
  description = "The subnet ids for efs"
  type = "list"
}

variable "security_groups" {
  description = "Additional security groups"
  type = "list"
  default = []
}

variable "mount_point" {
  description = "Mount point used to mount the EFS filesystem on an instance in the userdata config provided by output.cloudinit_config"
  default = "/efs"
}
