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

output "primary_zone_id" {
  value = "${aws_route53_zone.primary.zone_id}"
}

output "internal_zone_id" {
  value = "${aws_route53_zone.internal.zone_id}"
}

output "default_security_group_id" {
  value = "${aws_default_security_group.default.id}"
}
