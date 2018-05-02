locals {
  ns_msg = <<-EOF
Certificate validation will not succeed until you register the
${var.domain} zone nameservers with your registrar

${join("\n", var.zone_name_servers)}
  EOF

  ns_ipc = "${jsonencode(map(
    "action", "notify",
    "message", local.ns_msg,
    "modal", "true"
  ))}"
}

// domain and *.domain end up getting collapsed into a single domain_validation_options
resource "aws_acm_certificate" "primary" {
  domain_name = "${var.domain}"
  subject_alternative_names = "${var.alternative_names}"
  validation_method = "DNS"

  provisioner "local-exec" {
    command = "$ATMOS_IPC_CLIENT '${local.ns_ipc}'"
    on_failure = "continue"
  }

  tags {
    Name = "${var.local_name_prefix}primary-cert"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

locals {
  wildcard = "*.${var.domain}"
  all_names = "${concat(list(var.domain), var.alternative_names)}"
  names_without_wildcard = "${compact(split(",", replace(join(",", local.all_names), local.wildcard, "")))}"
}

resource "aws_route53_record" "cert_validation" {
  count   = "${length(local.names_without_wildcard)}"

  name    = "${lookup(aws_acm_certificate.primary.domain_validation_options[count.index], "resource_record_name")}"
  type    = "${lookup(aws_acm_certificate.primary.domain_validation_options[count.index], "resource_record_type")}"
  zone_id = "${var.zone_id}"
  records = ["${lookup(aws_acm_certificate.primary.domain_validation_options[count.index], "resource_record_value")}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = "${aws_acm_certificate.primary.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.*.fqdn}"]
}
