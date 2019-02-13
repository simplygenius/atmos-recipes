output "hostname" {
  description = "The hostname alias assigned to the database"
  value = "${aws_route53_record.main.fqdn}"
}

output "port" {
  description = "The port the database listens on"
  value = "${var.port}"
}
