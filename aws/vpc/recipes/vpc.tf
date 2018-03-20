variable "az_count" {
  description = "The number of AZs to use for redundancy"
  default = 2
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default = "10.10.0.0/16"
}

variable "permissive_default_security_group" {
  description = <<-EOF
    Sets up the default security group to allow permissive internal ingress,
    external egress, or both. Its safe and usually desired to leave this set to
    "egress" (e.g. to allow all instances to reach out to the internet to
    download packages, etc), and rely on ingress rules for preventing internal
    communication.  If set to "ingress" or "both", it also sets up the default
    security group to allow permissive internal access. That is, all resources
    that have the default security group will allow access on any port/protocol
    from any other resource that also has the default security group. Its a
    good idea to leave this off and setup security group rules for ingress on a
    case by case basis (e.g. instance -> rds).  However, it does come in handy
    for debugging.  Set to "none" to setup an empty default security group, and
    anything else to leave it untouched.
  EOF
  default = "egress"
}


module "vpc" {
  source = "../modules/vpc"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  account_ids = "${var.account_ids}"

  az_count = "${var.az_count}"
  vpc_cidr = "${var.vpc_cidr}"

  permissive_default_security_group = "${var.permissive_default_security_group}"
}
