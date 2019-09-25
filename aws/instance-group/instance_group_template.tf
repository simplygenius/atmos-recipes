module "instance-group-<%= name %>" {
  source = "../modules/instance-group-dynamic"

  atmos_env = var.atmos_env
  global_name_prefix = var.global_name_prefix
  local_name_prefix = var.local_name_prefix
  name = "<%= name %>"

  region = var.region
  account_ids = var.account_ids

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  security_groups = module.vpc.security_group_ids

  image_id = lookup(var.instance_images, "<%= name %>", local.instance_images_default)
  instance_type = lookup(var.instance_types, "<%= name %>", var.instance_types_default)
  keypair_name = lookup(var.instance_keypairs, "<%= name %>", var.instance_keypairs_default)
  instance_desired = lookup(var.instance_counts, "<%= name %>", var.instance_counts_default)
  <%- if auto_scale -%>
  min_scale_factor = var.instance_min_count_scale_factor
  max_scale_factor = var.instance_max_count_scale_factor
  <%- end -%>
  cloudwatch_alarm_target = local.ops_alerts_topic_arn

  <%- if load_balancer != :none -%>
  target_groups = [module.instance-group-load-balancer-<%= name %>.lb_target_group_id]
  <%- end -%>

  user_data = module.instance-group-userdata-<%= name %>.rendered
}

module "instance-group-userdata-<%= name %>" {
  source = "../modules/atmos-user-data"

  atmos_env = var.atmos_env
  global_name_prefix = var.global_name_prefix
  local_name_prefix = var.local_name_prefix
  name = "<%= name %>"
  account_ids = var.account_ids

  instance_role = module.instance-group-<%= name %>.instance_role
  lock_table = local.instance_group_lock_table
  lock_key = local.instance_group_lock_key
  zone_id = module.dns.private_zone_id
  iam_inspect_role = module.instance-group-iam-inspect-for-ssh.upstream_role
  iam_permission_groups = local.iam_permission_groups
  policies = [
    {
      name = "${var.local_name_prefix}iam-inspect-for-ssh"
      policy = module.instance-group-iam-inspect-for-ssh.downstream_policy
    }
  ]
}

<%- if auto_scale -%>

module "instance-group-autoscale-<%= name %>" {
  source = "../modules/auto-scaling-policy"

  atmos_env = var.atmos_env
  global_name_prefix = var.global_name_prefix
  local_name_prefix = var.local_name_prefix
  name = "<%= name %>"

  auto_scaling_name = module.instance-group-<%= name %>.auto_scaling_name
}

<%- end # auto_scale -%>

<%- if load_balancer != :none -%>

module "instance-group-load-balancer-<%= name %>" {
  <%- if lb_type == :network -%>
  source = "../modules/nlb"
  <%- else -%>
  source = "../modules/alb"
  <%- end -%>

  atmos_env = var.atmos_env
  global_name_prefix = var.global_name_prefix
  local_name_prefix = var.local_name_prefix
  name = "<%= name %>"

  internal = <%= load_balancer == :internal %>
  listener_cidr = "<%= load_balancer == :external ? '0.0.0.0/0' : '${var.vpc_cidr}' %>"
  zone_id = module.dns.<%= load_balancer == :external ? 'public' : 'private' %>_zone_id
  subnet_ids = module.vpc.<%= load_balancer == :external  ? 'public' : 'private' %>_subnet_ids
  vpc_id = module.vpc.vpc_id
  logs_bucket = aws_s3_bucket.logs.bucket

  target_type = "instance"
  <%- if lb_type == :network -%>
  listener_port = "<%= port %>"
  destination_port = "<%= port %>"
  <%- else -%>
  alb_certificate_arn = module.wildcart-cert.certificate_arn
  <%- end -%>
  destination_security_group = module.instance-group-<%= name %>.security_group_id

  cloudwatch_alarm_target = local.ops_alerts_topic_arn
}

<%- end # load_balancer -%>
