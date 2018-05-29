output "hostname" {
  description = "The hostname alias created for this load balancer"
  value = "${aws_route53_record.main.fqdn}"
}

output "alb_id" {
  description = "The id of the load balancer"
  value = "${aws_alb.main.id}"
}

output "alb_target_group_id" {
  description = "The target group id of the load balancer"
  value = "${aws_alb_target_group.main.id}"
}

output "alb_zone_id" {
  description = "The zone id of the load balancer"
  value = "${aws_alb.main.zone_id}"
}

output "alb_dns_name" {
  description = "The aws assigned dns name of the load balancer"
  value = "${aws_alb.main.dns_name}"
}

output "security_group_id" {
  description = "The security group used to grant the load balancer network permissions"
  value = "${aws_security_group.default.id}"
}
