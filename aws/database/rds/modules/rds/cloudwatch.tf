resource "aws_cloudwatch_metric_alarm" "cpu-high" {
  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"

  alarm_name          = "${var.local_name_prefix}rds-${var.name}-cpu-high"
  alarm_description   = "Alarm when cpu is too high"

  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "90"

  evaluation_periods  = "3"
  period              = "300"
  statistic           = "Average"
  alarm_actions       = ["${var.cloudwatch_alarm_target}"]

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.main.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "storage-low" {
  count = "${var.cloudwatch_alarm_target == "" ? 0 : 1}"

  alarm_name          = "${var.local_name_prefix}rds-${var.name}-storage-low"
  alarm_description   = "Alarm when storage is too low"

  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"

  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "100000000"

  evaluation_periods  = "3"
  period              = "60"
  statistic           = "Average"
  alarm_actions       = ["${var.cloudwatch_alarm_target}"]

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.main.id}"
  }
}
