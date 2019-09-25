resource "aws_autoscaling_policy" "scale-up" {
  name                   = "${var.local_name_prefix}${var.name}-up"
  scaling_adjustment     = var.up_scaling_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.up_scaling_cooldown
  autoscaling_group_name = var.auto_scaling_name
}

resource "aws_autoscaling_policy" "scale-down" {
  name                   = "${var.local_name_prefix}${var.name}-down"
  scaling_adjustment     = var.down_scaling_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.down_scaling_cooldown
  autoscaling_group_name = var.auto_scaling_name
}

resource "aws_cloudwatch_metric_alarm" "scale-up-alarm-high" {
  alarm_name          = "${var.local_name_prefix}${var.name}-scale-up-alarm-high"
  alarm_description   = "Watches for high state for auto-scaling"
  comparison_operator = var.up_scaling_comparison_operator
  dimensions = {
    AutoScalingGroupName = var.auto_scaling_name
  }
  evaluation_periods        = var.up_scaling_evaluation_periods
  metric_name               = var.up_scaling_metric_name
  namespace                 = var.up_scaling_metric_namespace
  period                    = var.up_scaling_period
  statistic                 = var.up_scaling_statistic
  threshold                 = var.up_scaling_threshold
  insufficient_data_actions = []
  alarm_actions             = [aws_autoscaling_policy.scale-up.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale-down-alarm-low" {
  alarm_name          = "${var.local_name_prefix}${var.name}-scale-down-alarm-low"
  alarm_description   = "Watches for low state for auto-scaling"
  comparison_operator = var.down_scaling_comparison_operator
  dimensions = {
    AutoScalingGroupName = var.auto_scaling_name
  }
  evaluation_periods        = var.down_scaling_evaluation_periods
  metric_name               = var.down_scaling_metric_name
  namespace                 = var.down_scaling_metric_namespace
  period                    = var.down_scaling_period
  statistic                 = var.down_scaling_statistic
  threshold                 = var.down_scaling_threshold
  insufficient_data_actions = []
  alarm_actions             = [aws_autoscaling_policy.scale-down.arn]
}

