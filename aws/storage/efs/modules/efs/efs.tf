resource "aws_security_group" "default" {
  name   = "${var.local_name_prefix}efs-${var.name}"
  vpc_id = var.vpc_id
}

resource "aws_efs_file_system" "primary" {
  tags = {
    Name        = "${var.local_name_prefix}${var.name}"
    Environment = var.atmos_env
    Source      = "terraform"
  }
}

resource "aws_efs_mount_target" "primary" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.primary.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = flatten([
    aws_security_group.default.id,
    compact(var.security_groups),
  ])
}

