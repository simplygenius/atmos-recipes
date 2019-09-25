resource "aws_security_group" "default" {
  name   = "${var.local_name_prefix}alb-${var.name}"
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.local_name_prefix}alb-${var.name}"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_security_group_rule" "allow-ingress-to-lb-http" {
  count = signum(length(var.listener_cidr))

  security_group_id = aws_security_group.default.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = var.listener_port
  to_port   = var.listener_port

  cidr_blocks = [var.listener_cidr]
}

resource "aws_security_group_rule" "allow-ingress-to-lb-https" {
  count = signum(length(var.listener_cidr)) * signum(var.enable_https)

  security_group_id = aws_security_group.default.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = var.listener_https_port
  to_port   = var.listener_https_port

  cidr_blocks = [var.listener_cidr]
}

locals {
  dest_from_port = var.destination_port
  dest_to_port   = var.destination_port_to == "" ? var.destination_port : var.destination_port_to
}

resource "aws_security_group_rule" "allow-egress-from-lb-to-destination" {
  security_group_id        = aws_security_group.default.id
  source_security_group_id = var.destination_security_group

  type      = "egress"
  protocol  = "tcp"
  from_port = local.dest_from_port
  to_port   = local.dest_to_port
}

resource "aws_security_group_rule" "allow-ingress-to-destination-from-lb" {
  security_group_id        = var.destination_security_group
  source_security_group_id = aws_security_group.default.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = local.dest_from_port
  to_port   = local.dest_to_port
}

resource "aws_lb" "main" {
  name = "${var.local_name_prefix}alb-${var.name}"

  internal           = var.internal
  load_balancer_type = "application"
  idle_timeout       = var.idle_timeout
  subnets            = var.subnet_ids
  security_groups = flatten([
    aws_security_group.default.id,
    compact(var.security_groups),
  ])

  access_logs {
    bucket = var.logs_bucket
    prefix = "lb-access-logs/${var.name}"
  }

  tags = {
    Name        = "${var.local_name_prefix}${var.name}"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.id
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "main-https" {
  count = signum(var.enable_https)

  load_balancer_arn = aws_lb.main.id
  port              = var.listener_https_port
  protocol          = "HTTPS"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "main" {
  name = "${var.local_name_prefix}alb-${var.name}"

  vpc_id      = var.vpc_id
  target_type = var.target_type

  protocol             = "HTTP"
  port                 = var.destination_port
  deregistration_delay = var.deregistration_delay

  dynamic "health_check" {
    for_each = [merge(var.health_check, var.health_check_override)]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      interval            = lookup(health_check.value, "interval", null)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
    }
  }

  tags = {
    Name        = "${var.local_name_prefix}${var.name}"
    Environment = var.atmos_env
    Source      = "atmos"
  }
}

resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = format(var.host_format, var.name)
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
