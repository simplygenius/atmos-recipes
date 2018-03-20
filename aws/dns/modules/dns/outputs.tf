output "public_zone_id" {
  value = "${aws_route53_zone.public.zone_id}"
}

output "private_zone_id" {
  value = "${aws_route53_zone.private.zone_id}"
}

output "public_zone_name_servers" {
  value = "${aws_route53_zone.public.name_servers}"
}
