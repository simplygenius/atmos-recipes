variable "atmos_env" {
  description = "The atmos environment"
}

variable "global_name_prefix" {
  description = <<-EOF
    The global name prefix for disambiguating resource names that have a global
    scope (e.g. s3 bucket names)
EOF


  default = ""
}

variable "local_name_prefix" {
  description = <<-EOF
    The local name prefix for disambiguating resource names that have a local scope
    (e.g. when running multiple environments in the same account)
EOF


  default = ""
}

variable "domain" {
  description = "The domain name to create a certificate for"
}

variable "alternative_names" {
  description = "The other names to include in the certificate for domain"
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "The zone hosting the domain for the certificate"
}

variable "zone_name_servers" {
  description = "The name servers for the zone so we can remind user to add to registrar"
  type        = list(string)
}

