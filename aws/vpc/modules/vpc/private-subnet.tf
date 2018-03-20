resource "aws_subnet" "private" {
  count = "${length(local.private_subnet_cidrs)}"

  vpc_id = "${aws_vpc.primary.id}"
  cidr_block = "${local.private_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.zones.names[count.index]}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.local_name_prefix}private-primary-subnet"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_route_table" "private" {
  count = "${length(local.private_subnet_cidrs)}"

  vpc_id = "${aws_vpc.primary.id}"

  tags {
    Name = "${var.local_name_prefix}private-routes"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_route" "private-nat" {
  count = "${length(local.private_subnet_cidrs)}"

  route_table_id = "${aws_route_table.private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.default.*.id[count.index]}"
}

resource "aws_route_table_association" "private" {
  count = "${length(local.private_subnet_cidrs)}"

  subnet_id = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
}
