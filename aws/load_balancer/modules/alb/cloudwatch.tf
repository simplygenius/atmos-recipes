resource "aws_cloudwatch_metric_alarm" "unhealthy-hosts" {
  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"

  alarm_name          = "${var.local_name_prefix}alb-${var.name}-unhealthy-hosts"
  alarm_description   = "Alarm when there are any unhealthy hosts"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "0"

  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Sum"
  alarm_actions       = ["${var.cloudwatch_alarm_target}"]

  dimensions {
    LoadBalancer = "${aws_alb.main.arn_suffix}"
  }
}

resource "aws_cloudwatch_metric_alarm" "too-many-500s" {
  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"

  alarm_name          = "${var.local_name_prefix}alb-${var.name}-too-many-500s"
  alarm_description   = "Alarm when 500s exceed threshold"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${var.cloudwatch_max_500_count}"

  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Sum"
  alarm_actions       = ["${var.cloudwatch_alarm_target}"]

  dimensions {
    LoadBalancer = "${aws_alb.main.arn_suffix}"
  }
}
