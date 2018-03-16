resource "aws_route53_zone" "primary" {
  name = "${var.domain}"

  tags {
    Name = "${var.local_name_prefix}primary-zone"
    Environment = "${var.atmos_env}"
    Source = "Atmos"
  }
}

resource "aws_route53_zone" "internal" {
  name = "${var.domain}"
  vpc_id = "${aws_vpc.primary.id}"

  tags {
    Name = "${var.local_name_prefix}internal-zone"
    Environment = "${var.atmos_env}"
    Source = "Atmos"
  }
}
