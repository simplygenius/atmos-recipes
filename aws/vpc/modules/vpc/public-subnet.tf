resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name        = "${var.local_name_prefix}public-gateway"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_eip" "nat_gateway_ip" {
  count = local.nat_count

  vpc = true
}

resource "aws_nat_gateway" "default" {
  count = local.nat_count

  allocation_id = aws_eip.nat_gateway_ip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.default]
}

resource "aws_subnet" "public" {
  count = length(local.public_subnet_cidrs)

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.default]

  tags = {
    Name        = "${var.local_name_prefix}public-subnet"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_route_table" "public" {
  count = length(local.public_subnet_cidrs)

  vpc_id = aws_vpc.primary.id

  tags = {
    Name        = "${var.local_name_prefix}public-routes"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_route" "public" {
  count = length(local.public_subnet_cidrs)

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table_association" "public" {
  count = length(local.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

