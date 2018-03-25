resource "aws_security_group" "default" {
  name = "${var.local_name_prefix}alb-${var.name}"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.local_name_prefix}alb-${var.name}"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_alb" "main" {
  name            = "${var.local_name_prefix}alb-${var.name}"

  internal = "${var.internal}"
  idle_timeout = "${var.idle_timeout}"
  subnets         = ["${var.subnet_ids}"]
  security_groups = [
    "${aws_security_group.default.id}",
    "${compact(var.security_groups)}"
  ]

  access_logs {
    bucket = "${var.logs_bucket}"
    prefix = "lb-access-logs/${var.name}"
  }

  tags {
    Name = "${var.local_name_prefix}${var.name}"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "${var.listener_port}"
  protocol          = "${var.listener_protocol}"

  default_action {
    target_group_arn = "${aws_alb_target_group.main.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "main-https" {
  count = "${signum(var.enable_https)}"

  load_balancer_arn = "${aws_alb.main.id}"
  port              = 443
  protocol          = "HTTPS"
  certificate_arn = "${var.alb_certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.main.id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "main" {
  name     = "${var.local_name_prefix}alb-${var.name}"

  vpc_id   = "${var.vpc_id}"
  target_type = "${var.target_type}"

  protocol = "${var.destination_protocol}"
  port     = "${var.destination_port}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    interval = "${var.health_check_interval}"
    path = "${var.health_check_path}"
    port = "${var.health_check_port}"
    protocol = "${var.health_check_protocol}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    matcher = "${var.health_check_matcher}"
  }

  tags {
    Name = "${var.local_name_prefix}${var.name}"
    Environment = "${var.atmos_env}"
    Source = "atmos"
  }
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${format(var.host_format, var.name)}"
  type = "A"

  alias {
    name = "${aws_alb.main.dns_name}"
    zone_id = "${aws_alb.main.zone_id}"
    evaluate_target_health = true
  }
}
