resource "aws_security_group" "default" {
  name = "${var.local_name_prefix}elasticsearch-${var.name}"
  vpc_id = "${var.vpc_id}"
}

data "aws_caller_identity" "current" {}

// double-dollar in variable default declaration doesn't work properly
// https://github.com/hashicorp/terraform/issues/18069
data "template_file" "access_policy_dummy" {
  template = "${var.access_policy_template}"
}

data "template_file" "access_policy" {
  template = "${data.template_file.access_policy_dummy.rendered}"

  vars {
    account_id     = "${data.aws_caller_identity.current.account_id}"
    domain_name = "${aws_elasticsearch_domain.main.domain_name}"
  }
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name     = "${aws_elasticsearch_domain.main.domain_name}"
  access_policies = "${chomp(data.template_file.access_policy.rendered)}"
}

resource "aws_iam_service_linked_role" "main" {
  aws_service_name = "es.amazonaws.com"
}

locals {
  is_zoned = "${lookup(var.cluster_config, "zone_awareness_enabled", false)}"
  subnet_count = "${local.is_zoned ? length(var.subnet_ids) : 1}"
}

resource "aws_elasticsearch_domain" "main" {
  depends_on = ["aws_iam_service_linked_role.main"]

  domain_name = "${var.local_name_prefix}${var.name}"
  elasticsearch_version = "${var.elasticsearch_version}"

  vpc_options {
    subnet_ids = ["${slice(var.subnet_ids, 0, local.subnet_count)}"]
    security_group_ids = ["${aws_security_group.default.id}", "${var.security_groups}"]
  }

  cluster_config = ["${var.cluster_config}"]

  advanced_options = "${var.advanced_options}"

  ebs_options = ["${var.ebs_options}"]

  snapshot_options = ["${var.snapshot_options}"]
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${format(var.host_format, var.name)}"
  type = "CNAME"
  ttl = "300"

  records = [
    "${aws_elasticsearch_domain.main.endpoint}"
  ]
}
