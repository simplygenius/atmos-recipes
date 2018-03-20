output "vpc_id" {
  value = "${aws_vpc.primary.id}"
}

output "zone_names" {
  value = "${slice(data.aws_availability_zones.zones.names, 0, var.az_count)}"
}

output "public_subnet_ids" {
  value = "${aws_subnet.public.*.id}"
}

output "private_subnet_ids" {
  value = "${aws_subnet.private.*.id}"
}

output "default_security_group_id" {
  value = "${element(concat(
    aws_default_security_group.default-both.*.id,
    aws_default_security_group.default-egress.*.id,
    aws_default_security_group.default-ingress.*.id,
    aws_default_security_group.default-none.*.id,
    list("")
  ), 0)}"
}
