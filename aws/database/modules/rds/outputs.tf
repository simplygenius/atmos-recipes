output "security_group_id" {
   value = "${aws_security_group.default.id}"
}

output "hostname" {
  value = "${aws_route53_record.main-db.fqdn}"
}

output "port" {
  value = "${aws_db_instance.main.port}"
}

output "database" {
  value = "${aws_db_instance.main.name}"
}

output "username" {
  value = "${aws_db_instance.main.username}"
}

output "password" {
  value = "${aws_db_instance.main.password}"
}
