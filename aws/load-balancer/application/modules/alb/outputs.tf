output "hostname" {
  description = "The hostname alias created for this load balancer"
  value       = aws_route53_record.main.fqdn
}

output "lb_id" {
  description = "The id of the load balancer"
  value       = aws_lb.main.id
}

output "lb_name" {
  description = "The name of the load balancer"
  value       = aws_lb.main.name
}

output "lb_arn_suffix" {
  description = "The arn suffix (for metric alarms) of the load balancer"
  value       = aws_lb.main.arn_suffix
}

output "lb_target_group_id" {
  description = "The target group id of the load balancer"
  value       = aws_lb_target_group.main.id
}

output "lb_zone_id" {
  description = "The zone id of the load balancer"
  value       = aws_lb.main.zone_id
}

output "lb_dns_name" {
  description = "The aws assigned dns name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "security_group_id" {
  description = "The security group used to grant the load balancer network permissions"
  value       = aws_security_group.default.id
}

