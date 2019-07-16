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

variable "destination_security_group" {
  description = "The destination's security group used for adding rules to give listeners access"
}

variable "listener_port" {
  description = "The port to listen on, 80 by default"
  default = "80"
}

variable "listener_cidr" {
  description = "The cidr used to grant ingress to the load balancer"
}

variable "logs_bucket" {
  description = "The bucket to use for logging"
  default = ""
}

variable "internal" {
  description = "Makes the LB internal facing (also need to set subnets to private, and zone to internal)"
  default = true
}

variable "vpc_id" {
  description = "The vpc for the lb's security group"
}

variable "target_type" {
  description = "The lb's target_type"
  default = "ip"
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  default = 60
}

variable "destination_port" {
  description = "The destination port of the container"
}

variable "health_check" {
  description = "A map containing the values to configure the health check for the target"
  type = "map"
  default = {
    interval = 30
    port = "traffic-port"
    protocol = "TCP"
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

variable "health_check_override" {
  description = "Convenience to allow overriding a subset of the health_check default values"
  type = "map"
  default = {}
}

variable "host_format" {
  description = "The format used to register the friendly hostname of the LB in route53 - the formatter is passed the service name"
  default = "%s"
}

variable "deregistration_delay" {
  description = "The amount of time the LB waits to drain active connections when deregistering targets (e.g. during a deploy)"
  default = 30
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
}
