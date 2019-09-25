output "certificate_arn" {
  description = "The arn of the certificate that was created by this module"
  value       = join("", aws_acm_certificate_validation.cert.*.certificate_arn)
}

