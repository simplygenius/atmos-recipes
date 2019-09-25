resource "aws_route53_zone" "public" {
  name          = var.domain
  force_destroy = var.force_destroy

  tags = {
    Name        = "${var.local_name_prefix}public-zone"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_route53_zone" "private" {
  name          = var.domain
  force_destroy = var.force_destroy

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name        = "${var.local_name_prefix}private-zone"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_vpc_dhcp_options" "private-dhcp-options" {
  domain_name = aws_route53_zone.private.name

  domain_name_servers = [
    "AmazonProvidedDNS",
  ]

  tags = {
    Name        = "${var.local_name_prefix}private-dhcp-options"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_vpc_dhcp_options_association" "private-dhcp-options" {
  vpc_id          = var.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.private-dhcp-options.id
}

