resource "aws_security_group" "default" {
  name = "${var.local_name_prefix}elasticache-${var.name}"
  vpc_id = "${var.vpc_id}"
}

resource "aws_elasticache_parameter_group" "main" {
  name = "${var.local_name_prefix}${var.name}"
  family = "${var.family}"
  description = "${var.local_name_prefix}${var.name} param group"

  // This won't work till the following is fixed: https://github.com/hashicorp/terraform/issues/7705
  parameter = "${var.parameter}"
}

resource "aws_elasticache_subnet_group" "main" {
  name = "${var.local_name_prefix}${var.name}"
  description = "${var.local_name_prefix}${var.name} subnet group"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_elasticache_cluster" "main" {
  cluster_id = "${var.local_name_prefix}${var.name}"
  engine = "${var.engine}"
  engine_version = "${var.engine_version}"
  node_type = "${var.node_type}"
  port = "${var.port}"
  num_cache_nodes = "${var.node_count}"

  snapshot_retention_limit = "${var.snapshot_limit}"

  parameter_group_name = "${aws_elasticache_parameter_group.main.name}"
  subnet_group_name = "${aws_elasticache_subnet_group.main.name}"
  security_group_ids = ["${aws_security_group.default.id}", "${var.security_groups}"]

  tags {
    Name = "${var.local_name_prefix}${var.name}"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${format(var.host_format, var.name)}"
  type = "CNAME"
  ttl = "300"

  records = [
    "${aws_elasticache_cluster.main.cache_nodes.0.address}"
  ]
}
