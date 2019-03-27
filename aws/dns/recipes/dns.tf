
variable "domain" {
  description = "The primary domain name for your organization"
}

variable "force_destroy_zones" {
  description = <<-EOF
    Allows destruction of route53 zones that have contents.  Set to true for
    error-free destroys, but should be false for day to day usage.  Note you
    need to apply with it set to true in order for it to take effect in a
    destroy.  e.g.
      TF_VAR_force_destroy_zones=true atmos apply
      TF_VAR_force_destroy_zones=true atmos destroy
  EOF
  default = false
}

module "dns" {
  source = "../modules/dns"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"

  domain = "${var.domain}"
  vpc_id = "${module.vpc.vpc_id}"
  force_destroy = "${var.force_destroy_zones}"
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
