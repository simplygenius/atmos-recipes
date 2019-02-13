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

variable "vpc_id" {
  description = "The VPC id"
}

variable "zone_id" {
  description = "The zone id for registering the endpoint - can be public or private"
}

variable "subnet_ids" {
  description = "The subnet ids for components that need them - can be public or private"
  type = "list"
}

variable "security_groups" {
  description = "The security groups associated with the instance"
  type = "list"
  default = []
}

variable "host_format" {
  description = <<EOF
    The format used to register the friendly hostname in route53 -
    the formatter is passed the component name
  EOF
  default = "%s-cache"
}

variable "az_mode" {
  description = "Determines how to distribute multiple nodes across AZs, single-az or cross-az"
  default = "single-az"
}

variable "parameter" {
  description = "The parameters for the instance's parameter group"
  type = "list"
  default = []
}

variable "family" {
  description = "The elasticache family"
  default = "redis5.0"
}

variable "engine" {
  description = "The elasticache engine: memcached, redis"
  default = "redis"
}

variable "engine_version" {
  description = "The elasticache engine version"
  default = "5.0"
}

variable "port" {
  description = "The elasticache port"
  default = "6379"
}

variable "node_type" {
  description = "The elasticache node type"
  default = "cache.m3.medium"
}

variable "node_count" {
  description = "The number of elasticache nodes"
  default = "1"
}

variable "snapshot_limit" {
  description = "The number of elasticache snapshots to retain, only works for redis"
  default = "3"
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default = ""
}
