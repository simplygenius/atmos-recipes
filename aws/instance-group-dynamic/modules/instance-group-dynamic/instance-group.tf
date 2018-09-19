locals {
  min_size = "${var.instance_min == -1 ? ceil(var.instance_desired / var.min_scale_factor) : var.instance_min}"
  max_size = "${var.instance_max == -1 ? var.instance_desired * var.max_scale_factor : var.instance_max}"
}

resource "aws_security_group" "default" {
  name = "${var.local_name_prefix}asg-${var.name}"
  vpc_id = "${var.vpc_id}"
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.local_name_prefix}${var.name}"
  role = "${aws_iam_role.main.name}"
}

resource "aws_iam_role" "main" {
  name = "${var.local_name_prefix}${var.name}"
  assume_role_policy = <<POLICY
{
"Version": "2008-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }
]
}
POLICY
}

resource "aws_autoscaling_group" "main" {
  lifecycle {
    create_before_destroy = true
  }
  name = "${var.recreate_instances_on_update == 1 ? aws_launch_configuration.main.id : "${var.local_name_prefix}${var.name}"}"
  min_size = "${local.min_size}"
  desired_capacity = "${var.instance_desired}"
  max_size = "${local.max_size}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type = "EC2"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.main.name}"
  vpc_zone_identifier = [
    "${var.subnet_ids}"]
  load_balancers = [
    "${var.load_balancers}"]
  target_group_arns = ["${var.target_groups}"]

  tag = {
    key = "Source"
    value = "terraform"
    propagate_at_launch = true
  }

}

locals {
  encoded_user_data = "${length(var.user_data) == 0 ? "" : (var.user_data_compress ? base64gzip(var.user_data) : base64encode(var.user_data))}"
}

resource "aws_launch_configuration" "main" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "${var.local_name_prefix}${var.name}-lc-${var.image_id}-"
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.keypair_name}"
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  security_groups = [
    "${aws_security_group.default.id}",
    "${compact(var.security_groups)}"
  ]

  // Using user_data instead of user_data_base64 so we get reduced plan output.
  // Should be fine as recent terraforms don't base64 encode user_data if already
  // encoded.
  user_data = "${local.encoded_user_data}"

  associate_public_ip_address = "${var.associate_public_ip_address}"
  enable_monitoring = false

  root_block_device = "${var.root_block_devices}"
  ebs_block_device = "${var.ebs_block_devices}"
  ephemeral_block_device = "${var.ephemeral_block_devices}"
}
