resource "aws_vpc" "primary" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.vpc_tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.local_name_prefix}primary-vpc"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

// A global mutable seurity group since the aws_default_security_group is not mutable after the fact
resource "aws_security_group" "global" {
  name   = "${var.local_name_prefix}vpc-global"
  vpc_id = aws_vpc.primary.id
}

resource "aws_default_security_group" "default-both" {
  count  = var.permissive_default_security_group == "both" ? 1 : 0
  vpc_id = aws_vpc.primary.id

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
}

resource "aws_default_security_group" "default-egress" {
  count  = var.permissive_default_security_group == "egress" ? 1 : 0
  vpc_id = aws_vpc.primary.id

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_default_security_group" "default-ingress" {
  count  = var.permissive_default_security_group == "ingress" ? 1 : 0
  vpc_id = aws_vpc.primary.id

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
}

resource "aws_default_security_group" "default-none" {
  count  = var.permissive_default_security_group == "none" ? 1 : 0
  vpc_id = aws_vpc.primary.id
}

data "aws_availability_zones" "zones" {
}

