resource "aws_cloudwatch_metric_alarm" "unhealthy-hosts" {
  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"

  alarm_name          = "${var.local_name_prefix}nlb-${var.name}-unhealthy-hosts"
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
    LoadBalancer = "${aws_lb.main.arn_suffix}"
  }
}
