output "hostname" {
  value = "${aws_route53_record.main.fqdn}"
}

output "alb_id" {
  value = "${aws_alb.main.id}"
}

output "alb_target_group_id" {
  value = "${aws_alb_target_group.main.id}"
}

output "alb_zone_id" {
  value = "${aws_alb.main.zone_id}"
}

output "alb_dns_name" {
  value = "${aws_alb.main.dns_name}"
}

output "security_group_id" {
   value = "${aws_security_group.default.id}"
}
