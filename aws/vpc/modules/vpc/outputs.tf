output "vpc_id" {
  description = "The id of the vpc created by this module"
  value = "${aws_vpc.primary.id}"
}

output "zone_names" {
  description = "The aws availability zones used for this vpc"
  value = "${slice(data.aws_availability_zones.zones.names, 0, var.az_count)}"
}

output "public_subnet_ids" {
  description = "The subnet ids for the public subnets"
  value = "${aws_subnet.public.*.id}"
}

output "private_subnet_ids" {
  description = "The subnet ids for the private subnets"
  value = "${aws_subnet.private.*.id}"
}

output "default_security_group_id" {
  description = "The id for the default security group for this vpc"
  value = "${element(concat(
    aws_default_security_group.default-both.*.id,
    aws_default_security_group.default-egress.*.id,
    aws_default_security_group.default-ingress.*.id,
    aws_default_security_group.default-none.*.id,
    list("")
  ), 0)}"
}
