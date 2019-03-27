output "hostname" {
  description = "The hostname alias assigned to the database"
  value = "${aws_route53_record.main.fqdn}"
}

output "port" {
  description = "The port the database listens on"
  value = "${var.port}"
}

output "security_group_id" {
  description = "The security group used to grant network permissions"
  value = "${aws_security_group.default.id}"
}
