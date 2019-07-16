resource "aws_security_group_rule" "allow-ingress-to-lb" {
  count = "${signum(length(var.listener_cidr))}"

  security_group_id = "${var.destination_security_group}"

  type = "ingress"
  protocol = "tcp"
  from_port =  "${var.listener_port}"
  to_port = "${var.listener_port}"

  cidr_blocks = ["${var.listener_cidr}"]
}

resource "aws_lb" "main" {
  name            = "${var.local_name_prefix}nlb-${var.name}"

  internal = "${var.internal}"
  load_balancer_type = "network"
  idle_timeout = "${var.idle_timeout}"
  subnets         = ["${var.subnet_ids}"]

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

resource "aws_lb_listener" "main" {
  load_balancer_arn = "${aws_lb.main.id}"
  port              = "${var.listener_port}"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.id}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.local_name_prefix}nlb-${var.name}"

  vpc_id   = "${var.vpc_id}"
  target_type = "${var.target_type}"

  protocol = "TCP"
  port     = "${var.destination_port}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check = ["${merge(var.health_check, var.health_check_override)}"]

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
    name = "${aws_lb.main.dns_name}"
    zone_id = "${aws_lb.main.zone_id}"
    evaluate_target_health = true
  }
}
