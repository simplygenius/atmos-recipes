variable "website_bucket" {
  description = "The bucket for hosting a static website"
}

module "static-website-www" {
  source = "../modules/static-website"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"

  name = "www"
  aliases = ["${var.domain}", "www.${var.domain}"]

  zone_id = "${module.dns.public_zone_id}"
  certificate_arn = "${module.wildcart-cert.certificate_arn}"
  site_bucket = "${var.website_bucket}"
  logs_bucket = "${var.logs_bucket}"
  force_destroy_buckets = "${var.force_destroy_buckets}"
}

data "template_file" "policy-deploy-static-website" {
  vars {
    site_bucket_arn = "${module.static-website-www.site_bucket_arn}"
  }

  template = "${file("../templates/policy-deploy-static-website.tmpl.json")}"
}

resource "aws_iam_role_policy" "website-deploy-s3-access" {
  name = "${var.local_name_prefix}website-deploy-s3-access"
  role = "${aws_iam_role.deployer.name}"

  policy = "${data.template_file.policy-deploy-static-website.rendered}"
}
