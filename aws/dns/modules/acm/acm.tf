locals {
  ns_msg = <<-EOF
Certificate validation will not succeed until you register the
'${var.domain}' zone nameservers with your registrar

${join("\n", var.zone_name_servers)}
  EOF

  ns_ipc = "${jsonencode(map(
    "action", "notify",
    "message", local.ns_msg,
    "modal", "true"
  ))}"
}

resource "aws_acm_certificate" "primary" {
  domain_name = "${var.domain}"
  // subject_alternative_names = []
  validation_method = "DNS"

  provisioner "local-exec" {
    command = "echo '${local.ns_ipc}' | $ATMOS_IPC_CLIENT"
    on_failure = "continue"
  }

  tags {
    Name = "${var.local_name_prefix}primary-cert"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_route53_record" "cert_validation" {
  name = "${aws_acm_certificate.primary.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.primary.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.primary.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = "${aws_acm_certificate.primary.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
