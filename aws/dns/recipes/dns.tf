
variable "domain" {
  description = "The primary domain name for your organization"
}

module "dns" {
  source = "../modules/dns"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"

  domain = "${var.domain}"
  vpc_id = "${module.vpc.vpc_id}"
}

module "wildcart-cert" {
  source = "../modules/acm"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"

  domain = "${var.domain}"
  alternative_names = ["*.${var.domain}"]
  zone_id = "${module.dns.public_zone_id}"
  zone_name_servers = "${module.dns.public_zone_name_servers}"
}
