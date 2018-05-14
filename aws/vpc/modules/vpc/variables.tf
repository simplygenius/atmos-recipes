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

variable "az_count" {
  description = "The number of AZs to use for redundancy"
}

variable "enable_nat" {
  description = "Enable provisioning of NAT gateways for each subnet in the vpc"
  default = 1
}

variable "vpc_tenancy" {
  description = "Instance tenancy for the VPC"
  default = "default"
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

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default = "10.10.0.0/16"
}

variable "vpc_cidr_subnet_bits" {
  description = <<-EOF
    The number of bits to use for subdividing the vpc cidr into a sub-network
    for each AZ.  Changing this will cause a large number of changes to an
    exist ing VPC as the cidrs for all subnets will also change.  Since 3 bits
    gives 8 subnets, which is more than the number of AZs in a typical AWS
    account, you should never need to change it
  EOF
  default = 3
}

// See https://medium.com/aws-activate-startup-blog/practical-vpc-design-8412e1a18dcc#.493dx3uqd
// Our default of 3 bits give 8 networks, so with an az_count of 2, the subnets
// look like:
//
//  10.10.0.0/16 - VPC
//      10.10.0.0/19 - AZ A
//          10.10.0.0/20 - Private
//          10.10.16.0/20
//                  10.10.16.0/21 - Public
//                  10.10.24.0/21 - Spare
//      10.10.32.0/19 - AZ B
//          10.10.32.0/20 - Private
//          10.10.48.0/20
//                  10.10.48.0/21 - Public
//                  10.10.56.0/21 - Spare
//      10.10.64.0/19 - Spare
//      10.10.96.0/19 - Spare
//      10.10.128.0/19 - Spare
//      10.10.160.0/19 - Spare
//      10.10.192.0/19 - Spare
//      10.10.224.0/19 - Spare
//
//  16-bit: 65534 addresses
//  18-bit: 16382 addresses
//  19-bit: 8190 addresses
//  20-bit: 4094 addresses
//

// The even networks get used entirely for private addresses, and the odd
// networks get further split into 2 sub networks, one of which is for public
// addresses, the other as a spare.
//
data "template_file" "private_subnet_cidrs" {
  // Limit the max AZ subnets by the number of bits
  count = "${(var.az_count % floor(pow(2, var.vpc_cidr_subnet_bits)))}"
  // Each AZ subnet is divided into two (1 bit), with the even/first subnet
  // being the private one, and the odd/second subnet for public+spare (below)
  template = "${cidrsubnet(cidrsubnet(var.vpc_cidr, var.vpc_cidr_subnet_bits, count.index), 1, 0)}"
}

data "template_file" "public_subnet_cidrs" {
  count = "${(var.az_count % floor(pow(2, var.vpc_cidr_subnet_bits)))}"
  // Each AZ subnet is divided into two (1 bit), with the odd/second subnet
  // being for public use, further subdivided into 2 for the public subnet and
  // a spare one
  template = "${cidrsubnet(cidrsubnet(cidrsubnet(var.vpc_cidr, var.vpc_cidr_subnet_bits, count.index), 1, 1), 1, 0)}"
}

locals {
  nat_enablement = "${signum(var.enable_nat) == 1 ? 1 : 0}"
  private_subnet_cidrs = "${data.template_file.private_subnet_cidrs.*.rendered}"
  public_subnet_cidrs = "${data.template_file.public_subnet_cidrs.*.rendered}"
}
