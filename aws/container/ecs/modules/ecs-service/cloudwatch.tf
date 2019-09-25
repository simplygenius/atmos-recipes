resource "aws_cloudwatch_metric_alarm" "memory-utilization" {
  count = var.cloudwatch_alarm_target == "" ? 0 : 1

  alarm_name                = "${var.local_name_prefix}${var.name}-memory-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ECS"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "95"
  alarm_description         = "This metric monitors ecs memory utilization for ${var.local_name_prefix}${var.name}"
  insufficient_data_actions = []
  alarm_actions             = [var.cloudwatch_alarm_target]

  dimensions = {
    ClusterName = element(split("/", var.ecs_cluster_arn), 1)
    ServiceName = "${var.local_name_prefix}${var.name}"
  }
}

