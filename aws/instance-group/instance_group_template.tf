<%- if name -%>

module "instance-group-<%= name %>" {
  source = "../modules/instance-group-dynamic"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "<%= name %>"

  region = "${var.region}"
  account_ids = "${var.account_ids}"

  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnet_ids}"
  zone_id = "${module.dns.private_zone_id}"

  image_id = "${lookup(var.instance_images, "<%= name %>", local.instance_images_default)}"
  instance_type = "${lookup(var.instance_types, "<%= name %>", var.instance_types_default)}"
  keypair_name = "${lookup(var.instance_keypairs, "<%= name %>", var.instance_keypairs_default)}"
  instance_desired = "${lookup(var.instance_counts, "<%= name %>", var.instance_counts_default)}"
  <%- if auto_scale -%>
  min_scale_factor = "${var.instance_min_count_scale_factor}"
  max_scale_factor = "${var.instance_max_count_scale_factor}"
  <%- end -%>
  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"
}


<%- if auto_scale -%>

module "instance-group-autoscale-<%= name %>" {
  source = "../modules/auto-scaling-policy"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "<%= name %>"

  auto_scaling_name = "${module.instance-group-<%= name %>.auto_scaling_name}"
}

<%- end # auto_scale -%>

<%- end # name -%>
