resource "aws_security_group" "default" {
  name   = "${var.name_prefix}efs-${var.name}"
  vpc_id = var.vpc_id
}

// TODO
