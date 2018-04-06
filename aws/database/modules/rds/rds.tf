resource "aws_db_parameter_group" "main" {
  count = "${var.parameter_group_name == "" ? 1 : 0}"

  name = "${var.local_name_prefix}${var.name}"
  family = "${var.family}"
  description = "RDS parameter group for ${var.name}"

  parameter = "${var.parameters}"
}

resource "aws_security_group" "default" {
  name = "${var.local_name_prefix}rds-${var.name}"
  vpc_id = "${var.vpc_id}"
}

resource "aws_db_subnet_group" "main" {
  name = "${var.local_name_prefix}${var.name}"
  description = "The db subnets for ${var.name}"

  subnet_ids = [
    "${var.subnet_ids}"
  ]

  tags {
    Name = "${var.local_name_prefix}${var.name}"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.local_name_prefix}${var.name}"

  engine = "${var.engine}"
  engine_version = "${var.engine_version}"

  instance_class = "${var.db_instance_type}"
  allocated_storage = "${var.db_instance_storage}"
  storage_encrypted = "${var.encrypted}"
  storage_type = "${var.db_instance_storage_type}"
  iops = "${var.db_instance_storage_iops}"

  multi_az = "${var.multi_az}"
  backup_retention_period = "${var.backup_retention_period}"
  final_snapshot_identifier = "${var.local_name_prefix}${var.name}-final"
  skip_final_snapshot = "${var.skip_final_snapshot}"

  username = "${var.db_username}"
  password = "${var.db_password}"
  name = "${var.db_name}"

  db_subnet_group_name = "${aws_db_subnet_group.main.name}"
  parameter_group_name = "${
    var.parameter_group_name == "" ?
      element(concat(aws_db_parameter_group.main.*.name, list("")), 0) :
      var.parameter_group_name
  }"

  vpc_security_group_ids = [
    "${aws_security_group.default.id}",
    "${var.security_groups}"
  ]

  tags {
    Name = "${var.local_name_prefix}${var.name}"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_route53_record" "main-db" {
  zone_id = "${var.zone_id}"
  name = "${format(var.host_format, var.name)}"
  type = "CNAME"
  ttl = "300"

  records = [
    "${aws_db_instance.main.address}"
  ]
}
