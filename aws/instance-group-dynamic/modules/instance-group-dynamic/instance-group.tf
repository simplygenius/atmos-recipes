locals {
  min_size = var.instance_min == -1 ? ceil(var.instance_desired / var.min_scale_factor) : var.instance_min
  max_size = var.instance_max == -1 ? var.instance_desired * var.max_scale_factor : var.instance_max
}

resource "aws_security_group" "default" {
  name   = "${var.local_name_prefix}asg-${var.name}"
  vpc_id = var.vpc_id
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.local_name_prefix}${var.name}"
  role = aws_iam_role.main.name
}

resource "aws_iam_role" "main" {
  name               = "${var.local_name_prefix}${var.name}"
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
  name                      = var.recreate_instances_on_update == 1 ? aws_launch_configuration.main.id : "${var.local_name_prefix}${var.name}"
  min_size                  = local.min_size
  desired_capacity          = var.instance_desired
  max_size                  = local.max_size
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.main.name
  vpc_zone_identifier       = var.subnet_ids
  load_balancers            = var.load_balancers
  target_group_arns         = var.target_groups

  tags = concat(
      [
        {
          "key"                 = "Source"
          "value"               = "terraform"
          "propagate_at_launch" = true
        },
      ],
      var.tags
  )
}

locals {
  encoded_user_data = length(var.user_data) == 0 ? "" : var.user_data_compress ? base64gzip(var.user_data) : base64encode(var.user_data)
}

resource "aws_launch_configuration" "main" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix          = "${var.local_name_prefix}${var.name}-lc-${var.image_id}-"
  image_id             = var.image_id
  instance_type        = var.instance_type
  key_name             = var.keypair_name
  iam_instance_profile = aws_iam_instance_profile.main.name
  security_groups = flatten([
    aws_security_group.default.id,
    compact(var.security_groups),
  ])

  // Using user_data instead of user_data_base64 so we get reduced plan output.
  // Should be fine as recent terraforms don't base64 encode user_data if already
  // encoded.
  user_data = local.encoded_user_data

  associate_public_ip_address = var.associate_public_ip_address
  enable_monitoring           = false

  dynamic "root_block_device" {
    for_each = var.root_block_devices
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name           = ebs_block_device.value.device_name
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      no_device             = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_devices
    content {
      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
    }
  }
}

