output "certificate_arn" {
  value = "${join("", aws_acm_certificate_validation.cert.*.certificate_arn)}"
}
