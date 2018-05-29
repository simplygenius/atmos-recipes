output "public_zone_id" {
  description = "The zone id for the public facing route53 zone created by this module"
  value = "${aws_route53_zone.public.zone_id}"
}

output "private_zone_id" {
  description = "The zone id for the internal facing route53 zone created by this module"
  value = "${aws_route53_zone.private.zone_id}"
}

output "public_zone_name_servers" {
  description = "The name servers for the public facing route53 zone, used when registering this domain upstream"
  value = "${aws_route53_zone.public.name_servers}"
}
