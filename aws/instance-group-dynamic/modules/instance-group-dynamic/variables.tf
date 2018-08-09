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
  type = "map"
}

variable "region" {
  description = "The aws region"
}

variable "name" {
  description = "The component name"
}

variable "keypair_name" {
  description = "The name of the AWS keypair used when creating instances"
  default = ""
}

variable "instance_min" {
  description = "Min numbers of instances"
  default = -1
}

variable "instance_max" {
  description = "Max numbers of instances"
  default = -1
}

variable "instance_desired" {
  description = "Desired numbers of instances"
  default = 0
}

variable "min_scale_factor" {
  description = <<EOF
    The amount to scale min values against the desired instance count.  For example, a scale factor of 2 will set
    instance_min=ceil(instance_desired/2).  Setting instance_min will take precedence.
  EOF
  default = 1
}

variable "max_scale_factor" {
  description = <<EOF
    The amount to scale max values against the desired instance count.  For example, a scale factor of 2 will set
    instance_max=instance_desired*2.  Setting instance_max will take precedence.
  EOF
  default = 1
}

variable "vpc_id" {
  description = "VPC for instances"
}

variable "subnet_ids" {
  description = "Subnets for instances"
  type = "list"
}

variable "image_id" {
  description = "Image id (AMI) for instances"
}

variable "instance_type" {
  description = "Type of instances"
}

variable "root_block_devices" {
  description = "The type of volume to use for the root device for each instance"
  type = "list"
  default = [
    {
      volume_type = "gp2"
      volume_size = "100"
      delete_on_termination = true
    }
  ]
}

variable "ebs_block_devices" {
  description = "Additional ebs volumes to attach to each instance"
  type = "list"
  default = []
}

variable "ephemeral_block_devices" {
  description = "Additional ephemeral volumes to provision for each instance"
  type = "list"
  default = []
}

variable "load_balancers" {
  description = "The ELB instances to associate the ASG with"
  type = "list"
  default = []
}

variable "security_groups" {
  description = "The security groups to associate the ASG with"
  type = "list"
  default = []
}

variable "iam_inspect_role" {
  description = "The role to assume in ops account for inspecting iam"
  default = "iam-inspect"
}

variable "health_check_grace_period" {
  default = "300"
}

variable "associate_public_ip_address" {
  default = "false"
}

variable "recreate_instances_on_update" {
  description = <<-EOF
    Forces terraform to trigger the instances in the group to get recreated (sequentially) if a parameter that would
    affect them changes (e.g. ami)
  EOF
  default = 1
}

variable "user_data" {
  description = "The user data to pass in for instance initialization"
  default = ""
}

variable "user_data_compress" {
  description = "Compress the user data"
  default = true
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default = ""
}
