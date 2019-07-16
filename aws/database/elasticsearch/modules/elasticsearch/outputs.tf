output "hostname" {
  description = "The hostname alias assigned to the database"
  value = "${aws_route53_record.main.fqdn}"
}

output "endpoint" {
  description = "The endpoint hostname (for use via https)"
  value = "${aws_elasticsearch_domain.main.endpoint}"
}

output "security_group_id" {
  description = "The security group used to grant network permissions"
  value = "${aws_security_group.default.id}"
}
