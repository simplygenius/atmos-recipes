output "security_group_id" {
  description = "The security group used to grant network permissions"
  value       = aws_security_group.default.id
}

output "hostname" {
  description = "The hostname alias assigned to the database"
  value       = aws_route53_record.main-db.fqdn
}

output "port" {
  description = "The port the database listens on"
  value       = aws_db_instance.main.port
}

output "database" {
  description = "The database name"
  value       = aws_db_instance.main.name
}

output "username" {
  description = "The user for accessing the database"
  value       = aws_db_instance.main.username
}

output "password" {
  description = "The password for accessing the database"
  value       = aws_db_instance.main.password
}

