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

output "public_route_table_ids" {
  description = "The route table ids for the public subnets"
  value = "${aws_route_table.public.*.id}"
}

output "private_subnet_ids" {
  description = "The subnet ids for the private subnets"
  value = "${aws_subnet.private.*.id}"
}

output "private_route_table_ids" {
  description = "The route table ids for the private subnets"
  value = "${aws_route_table.private.*.id}"
}

locals {
  default_sg = "${element(concat(
    aws_default_security_group.default-both.*.id,
    aws_default_security_group.default-egress.*.id,
    aws_default_security_group.default-ingress.*.id,
    aws_default_security_group.default-none.*.id,
    list("")
  ), 0)}"
}

output "default_security_group_id" {
  description = "The id for the default security group for this vpc"
  value = "${local.default_sg}"
}

output "global_security_group_id" {
  description = "The id for the global security group for this vpc, for adding global rules after creation"
  value = "${aws_security_group.global.id}"
}

output "security_group_ids" {
  description = "A convenience for adding both vpc security group ids to resources"
  value = ["${local.default_sg}", "${aws_security_group.global.id}"]
}