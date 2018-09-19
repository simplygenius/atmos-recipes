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

variable "destination_security_group" {
  description = "The destination's security group used for adding rules to give listeners access"
}

variable "listener_port" {
  description = "The port to listen on, 80 by default"
  default = "80"
}

variable "listener_https_port" {
  description = "The https port to listen on, 443 by default"
  default = "443"
}

variable "listener_cidr" {
  description = "The cidr used to grant ingress to the load balancer"
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
  description = "The destination port of the container.  If destination_port_to is set, this will be the from port, otherwise it is used as both from/to"
  // The terraform config always requires the port to be set in the target
  // group, so we default to 80 as a stub
  default = 80
}

variable "destination_port_to" {
  description = "The 'to' destination port of the container.  Only needs to be set when using a port range, e.g. to connect LB to the ephemeral port range in ECS bridge mode"
  default = ""
}

variable "health_check" {
  description = "A map containing the values to configure the health check for the target"
  type = "map"
  default = {
    interval = 30
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = 200
  }
}

variable "health_check_override" {
  description = "Convenience to allow overriding a subset of the health_check default values"
  type = "map"
  default = {}
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
