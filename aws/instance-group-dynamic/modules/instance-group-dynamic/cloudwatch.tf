resource "aws_cloudwatch_metric_alarm" "cpu-high" {
  count = var.cloudwatch_alarm_target == "" ? 0 : 1

  alarm_name        = "${var.local_name_prefix}${var.name}-cpu-high"
  alarm_description = "Alarm when cpu is too high"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "90"

  evaluation_periods = "3"
  period             = "300"
  statistic          = "Average"
  alarm_actions = [
    var.cloudwatch_alarm_target,
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

// The disk/memory utilization metrics are collected by the cloudwatch agent
// that is setup as part of atmos-user-data.

resource "aws_cloudwatch_metric_alarm" "memory-high" {
  count = var.cloudwatch_alarm_target == "" ? 0 : 1

  alarm_name        = "${var.local_name_prefix}${var.name}-memory-high"
  alarm_description = "Alarm when memory utilization is too high"

  namespace   = "CWAgent"
  metric_name = "mem_used_percent"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "90"

  evaluation_periods = "3"
  period             = "300"
  statistic          = "Average"
  alarm_actions = [
    var.cloudwatch_alarm_target,
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

resource "aws_cloudwatch_metric_alarm" "disk-high" {
  count = var.cloudwatch_alarm_target == "" ? 0 : 1

  alarm_name        = "${var.local_name_prefix}${var.name}-disk-high"
  alarm_description = "Alarm when disk utilization is too high"

  namespace   = "CWAgent"
  metric_name = "disk_used_percent"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "90"

  evaluation_periods = "3"
  period             = "300"
  statistic          = "Average"
  alarm_actions = [
    var.cloudwatch_alarm_target,
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

