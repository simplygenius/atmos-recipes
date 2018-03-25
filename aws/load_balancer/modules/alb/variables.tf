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

variable "zone_id" {
  description = "The zone id for registering the endpoint - can be public or private"
}

variable "subnet_ids" {
  description = "The subnet ids for components that need them - can be public or private"
  type = "list"
}

variable "security_groups" {
  description = "Security groups to attach to the ALB"
  type = "list"
  default = []
}

variable "listener_port" {
  description = "The port to listen on, 80 by default"
  default = "80"
}

variable "listener_protocol" {
  description = "The protocol for the listen port, HTTP by default"
  default = "HTTP"
}

variable "enable_https" {
  description = "Trigger enabling of https listener with the given ACM cert"
  default = 1
}

variable "alb_certificate_arn" {
  description = "The ssl certificate for the ALB instance, causes the addition of a https listener"
  default = ""
}

variable "logs_bucket" {
  description = "The bucket to use for logging"
  default = ""
}

variable "internal" {
  description = "Makes the ALB internal facing (also need to set subnets to private, and zone to internal)"
  default = true
}

variable "vpc_id" {
  description = "The vpc for the alb's security group"
}

variable "target_type" {
  description = "The alb's target_type"
  default = "ip"
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  default = 60
}

variable "destination_port" {
  description = "The destination port of the container.  Only needed if we aren't using with ECS, as our ecs service module links dynamic ports to the target_groups"
  // The terraform config always requires the port to be set in the target
  // group, so we default to 80 as a stub
  default = 80
}

variable "destination_protocol" {
  description = "The destination protocol of the container"
  default = "HTTP"
}

variable "health_check_interval" {
  description = "Time period in secs between health checks"
  default = 30
}

variable "health_check_path" {
  description = "The url path to hit on the app server to determine health"
  default = "/"
}

variable "health_check_port" {
  description = "The port for the load balancer to determine health"
  default = "traffic-port"
}

variable "health_check_protocol" {
  description = "The protocol for the load balancer to determine health"
  default = "HTTP"
}

variable "health_check_timeout" {
  description = "Timeout when connecting to determine health"
  default = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of health checks that need to pass before marking healthy"
  default = 2
}

variable "health_check_unhealthy_threshold" {
  description = "The number of health checks that need to fail before marking unhealthy"
  default = 2
}

variable "health_check_matcher" {
  description = "The http code meaning success (single, csv or dashed-range)"
  default = 200
}

variable "host_format" {
  description = "The format used to register the friendly hostname of the ALB in route53 - the formatter is passed the service name"
  default = "%s"
}

variable "deregistration_delay" {
  description = "The amount of time the ALB waits to drain active connections when deregistering targets (e.g. during a deploy)"
  default = 30
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
}

variable "cloudwatch_max_500_count" {
  description = "The max number of 500s per period"
  default = 10
}
