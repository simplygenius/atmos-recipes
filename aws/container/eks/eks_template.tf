module "instance-group-eks-<%= name %>" {
  source = "../modules/instance-group-dynamic"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "eks-<%= name %>"

  region = "${var.region}"
  account_ids = "${var.account_ids}"

  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnet_ids}"
  security_groups = ["${module.vpc.security_group_ids}", "${module.eks-<%= name %>.node_security_group}"]
  user_data = "${module.instance-group-userdata-eks-<%= name %>.rendered}"
  tags = [
    {key="kubernetes.io/cluster/${module.eks-<%= name %>.cluster_name}", value="owned", propagate_at_launch=true}
  ]

  image_id = "${lookup(var.instance_images, "eks-<%= name %>", local.instance_images_default)}"
  instance_type = "${lookup(var.instance_types, "eks-<%= name %>", var.instance_types_default)}"
  keypair_name = "${lookup(var.instance_keypairs, "eks-<%= name %>", var.instance_keypairs_default)}"
  instance_desired = "${lookup(var.instance_counts, "eks-<%= name %>", var.instance_counts_default)}"
  min_scale_factor = "${var.instance_min_count_scale_factor}"
  max_scale_factor = "${var.instance_max_count_scale_factor}"
  cloudwatch_alarm_target = "${local.ops_alerts_topic_arn}"
}

module "instance-group-userdata-eks-<%= name %>" {
  source = "../modules/atmos-user-data"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "eks-<%= name %>"
  account_ids = "${var.account_ids}"

  user_data = "${module.eks-<%= name %>.user_data}"

  instance_role = "${module.instance-group-eks-<%= name %>.instance_role}"
  lock_table = "${local.instance_group_lock_table}"
  lock_key = "${local.instance_group_lock_key}"
  zone_id = "${module.dns.private_zone_id}"
  iam_inspect_role = "${module.instance-group-iam-inspect-for-ssh.upstream_role}"
  iam_permission_groups = "${local.iam_permission_groups}"
  policies = [
    {
      name = "${var.local_name_prefix}iam-inspect-for-ssh"
      policy = "${module.instance-group-iam-inspect-for-ssh.downstream_policy}"
    }
  ]
}

module "instance-group-autoscale-eks-<%= name %>" {
  source = "../modules/auto-scaling-policy"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "eks-<%= name %>"

  auto_scaling_name = "${module.instance-group-eks-<%= name %>.auto_scaling_name}"
}

module "eks-<%= name %>" {
  source = "../modules/eks"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  name = "<%= name %>"

  vpc_id = "${module.vpc.vpc_id}"
  // Both private and public subnets to allow internal or external load balancers
  subnet_ids = ["${module.vpc.private_subnet_ids}", "${module.vpc.public_subnet_ids}"]
  node_role = "${module.instance-group-eks-<%= name %>.ins}"
}
