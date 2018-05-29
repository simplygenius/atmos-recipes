resource "aws_cloudwatch_metric_alarm" "cpu-high" {
  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"

  alarm_name = "${var.local_name_prefix}ecs-${var.name}-cpu-high"
  alarm_description = "Alarm when cpu is too high"

  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold = "90"

  evaluation_periods = "3"
  period = "300"
  statistic = "Average"
  alarm_actions = [
    "${var.cloudwatch_alarm_target}"]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }
}

// TODO
//resource "aws_cloudwatch_metric_alarm" "memory-high" {
//  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"
//
//  alarm_name = "${var.local_name_prefix}ecs-${var.name}-memory-high"
//  alarm_description = "Alarm when memory utilization is too high"
//
//  namespace = "System/Linux"
//  metric_name = "MemoryUtilization"
//
//  comparison_operator = "GreaterThanOrEqualToThreshold"
//  threshold = "90"
//
//  evaluation_periods = "3"
//  period = "300"
//  statistic = "Average"
//  alarm_actions = [
//    "${var.cloudwatch_alarm_target}"]
//
//  dimensions {
//    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
//  }
//}
//
//resource "aws_cloudwatch_metric_alarm" "disk-high" {
//  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"
//
//  alarm_name = "${var.local_name_prefix}ecs-${var.name}-disk-high"
//  alarm_description = "Alarm when disk utilization is too high"
//
//  namespace = "System/Linux"
//  metric_name = "DiskSpaceUtilization"
//
//  comparison_operator = "GreaterThanOrEqualToThreshold"
//  threshold = "90"
//
//  evaluation_periods = "3"
//  period = "300"
//  statistic = "Average"
//  alarm_actions = [
//    "${var.cloudwatch_alarm_target}"]
//
//  dimensions {
//    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
//    MountPath = "/"
//    Filesystem = "/dev/xvda1"
//  }
//}
