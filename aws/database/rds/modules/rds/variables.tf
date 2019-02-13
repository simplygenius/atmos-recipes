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

variable "host_format" {
  description = <<EOF
    The format used to register the friendly hostname in route53 -
    the formatter is passed the component name
  EOF
  default = "%s-db"
}

variable "vpc_id" {
  description = "The vpc id"
}

variable "zone_id" {
  description = "The zone id for registering the endpoint - can be public or private"
}

variable "subnet_ids" {
  description = "The subnet ids for components that need them - can be public or private"
  type = "list"
}

variable "source_security_group" {
  description = "The source security group used for adding rules to the source access to the DB"
}

variable "security_groups" {
  description = "The security groups associated with the instance"
  type = "list"
  default = []
}

variable "parameters" {
  description = <<-EOF
    The db parameters for the instance, mutually exclusive with
    parameter_group_name.  A list of maps of: name=?, value=?, (optional)
    apply_method=immediate|pending-reboot
  EOF
  type = "list"
  default = []
}

variable "parameter_group_name" {
  description = <<-EOF
    The parameter group associated with the instance, mutually exclusive with
    parameters
  EOF
  default = ""
}

variable "engine" {
  description = "The database engine"
}

variable "engine_version" {
  description = "The database engine version"
}

variable "family" {
  description = "The database family"
}

variable "db_instance_type" {
  description = "The instance type for the database instance"
  default = "db.m3.medium"
}

variable "db_instance_storage" {
  description = "The allocated storage for the database instance"
  default = 10
}

variable "db_instance_storage_type" {
  description = "The storage type for the database instance"
  default = "gp2"
}

variable "db_instance_storage_iops" {
  description = "The iops if using provisioned iops (storage type = io1)"
  default = 0
}

variable "multi_az" {
  description = "Enable multi AZ for the database"
  default = false
}

variable "backup_retention_period" {
  description = "How long to keep backups"
  default = 3
}

variable "skip_final_snapshot" {
  description = "Flag to turn off the final snapshot on destruction"
  default = false
}

variable "encrypted" {
  description = "Turn on database encryption"
  default = false
}

variable "db_name" {
  description = "The name of the database"
}

variable "db_username" {
  description = "The username for the database"
}

variable "db_password" {
  description = "The username for the database"
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default = ""
}
