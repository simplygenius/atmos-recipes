variable "instance_keypairs" {
  description = "A map from instance group name to the keypair used for provisioning instances in that group"
  type = "map"
  default = {}
}

variable "instance_keypairs_default" {
  description = "The default value to use when a keypair for group name is not present in instance_keypair_names"
  default = ""
}

variable "instance_counts"  {
  description = "A map from instance group name to the number of instances min/max/desired in that group"
  type = "map"
  default = {}
}

variable "instance_counts_default" {
  description = "The default value to use when a count for group name is not present in instance_counts"
  default = 1
}

variable "instance_min_count_scale_factor" {
  description = "The scaling factor to use to calculate a minimum instance count (ceil(instance_count/factor)) when autoscaling a group"
  default = 1
}

variable "instance_max_count_scale_factor" {
  description = "The scaling factor to use to calculate a maximum instance count (instance_count * factor) when autoscaling a group"
  default = 1
}

variable "instance_types"  {
  description = "A map from instance group name to the instance type desired for that group"
  type = "map"
  default = {}
}

variable "instance_types_default" {
  description = "The default value to use when an instance type for group name is not present in instance_types"
  default = "t2.micro"
}

variable "instance_images"  {
  description = "A map from instance group name to the number of instances min/max/desired in that group"
  type = "map"
  default = {}
}

variable "instance_images_default" {
  description = "The default value to use when an image for group name is not present in instance_images"
  default = ""
}

locals {
  instance_images_default = "${var.instance_images_default == "" ? data.aws_ami.ubuntu.image_id : var.instance_images_default}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Ubuntu
}

data "aws_ami" "amazon" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

data "aws_ami" "amazon_ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # Amazon
}
