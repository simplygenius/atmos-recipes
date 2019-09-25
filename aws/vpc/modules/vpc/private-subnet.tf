resource "aws_subnet" "private" {
  count = length(local.private_subnet_cidrs)

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = local.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.local_name_prefix}private-primary-subnet"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_route_table" "private" {
  count = length(local.private_subnet_cidrs)

  vpc_id = aws_vpc.primary.id

  tags = {
    Name        = "${var.local_name_prefix}private-routes"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_route" "private-nat" {
  count = length(local.private_subnet_cidrs) * local.nat_enablement

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  // If just one NAT, then each private subnet will point to to it.  If
  // redundant NATs, then each private subnet will point to the NAT in its AZ
  // since private-subnets:public-subnets:AZs are 1:1:1
  nat_gateway_id = aws_nat_gateway.default[count.index % local.nat_count].id
}

resource "aws_route_table_association" "private" {
  count = length(local.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

