variable "atmos_env" {
  description = "The atmos environment"
}

variable "global_name_prefix" {
  description = <<-EOF
    The global name prefix for disambiguating resource names that have a global
    scope (e.g. s3 bucket names)
  EOF
  default = ""
}

variable "local_name_prefix" {
  description = <<-EOF
    The local name prefix for disambiguating resource names that have a local scope
    (e.g. when running multiple environments in the same account)
  EOF
  default = ""
}

variable "name" {
  description = "The component name"
}

variable "auto_scaling_name" {
  description = "The name of the auto scaling group this policy gets applied to"
}

variable "up_scaling_metric_name" {
  description = "The metric to watch for scaling events"
  default = "CPUUtilization"
}

variable "up_scaling_metric_namespace" {
  description = "The namespace of the metric to watch for scaling events"
  default = "AWS/EC2"
}

variable "up_scaling_adjustment" {
  description = "How many to scale by when scaling up"
  default = 1
}

variable "up_scaling_cooldown" {
  description = "How long to wait between scaling adjustments"
  default = 300
}

variable "up_scaling_comparison_operator" {
  description = "The comparison operator to use when checking the threshold for a scaling event"
  default = "GreaterThanOrEqualToThreshold"
}

variable "up_scaling_evaluation_periods" {
  description = "The number of periods needed to trigger a scaling event"
  default = 1
}

variable "up_scaling_period" {
  description = "The length of the period to evaluate for scaling events"
  default = 300
}

variable "up_scaling_statistic" {
  description = "The aggregator to use when watching a period for scaling events"
  default = "Average"
}

variable "up_scaling_threshold" {
  description = "The threshold to be met when watching a period for scaling events"
  default = 80
}

variable "down_scaling_metric_name" {
  description = "The metric to watch for scaling events"
  default = "CPUUtilization"
}

variable "down_scaling_metric_namespace" {
  description = "The namespace of the metric to watch for scaling events"
  default = "AWS/EC2"
}

variable "down_scaling_adjustment" {
  description = "How many to scale by when scaling down (usually a negative value)"
  default = -1
}

variable "down_scaling_cooldown" {
  description = "How long to wait between scaling adjustments"
  default = 300
}

variable "down_scaling_comparison_operator" {
  description = "The comparison operator to use when checking the threshold for a scaling event"
  default = "LessThanOrEqualToThreshold"
}

variable "down_scaling_evaluation_periods" {
  description = "The number of periods needed to trigger a scaling event"
  default = 1
}

variable "down_scaling_period" {
  description = "The length of the period to evaluate for scaling events"
  default = 300
}

variable "down_scaling_statistic" {
  description = "The aggregator to use when watching a period for scaling events"
  default = "Average"
}

variable "down_scaling_threshold" {
  description = "The threshold to be met when watching a period for scaling events"
  default = 20
}
