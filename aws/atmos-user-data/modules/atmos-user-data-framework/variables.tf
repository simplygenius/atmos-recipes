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

variable "additional_user_data" {
  description = "Additional user data script"
  default = ""
}

variable "additional_user_data_files" {
  type = "list"
  description = "Additional user data files in the form needed by the cloudinit-files module (list of maps of path/content/owner/permissions)"
  default = []
}

variable "cloudinit_config" {
  description = "Cloudinit config"
  default = ""
}

variable "additional_cloudinit_config" {
  description = "Additional cloudinit config"
  default = ""
}

variable "additional_environment" {
  description = <<-EOF
    Additional environment variables to set in the remote environment.  Note
    that environment is applied in a sorted order, so if you have an environment
    variable that depends on another, it needs to come after it in a string
    sort
  EOF
  type = "map"
  default = {}
}

variable "user_data_wrapper" {
  description = "User data wrapper script"
  default = "/opt/atmos/bin/user_data_wrapper.sh"
}

variable "user_data_dir" {
  description = "User data scripts"
  default = "/opt/atmos/user_data.d"
}

variable "user_data_log_dir" {
  description = "User data scripts logs"
  default = "/var/log/user_data"
}

variable "upgrade_packages" {
  description = "Set the flag to cloudinit to enable package upgrades on first boot"
  default = 1
}

variable "debug_user_data" {
  description = "Enables more verbose logging of user data scripts"
  default = 0
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default = ""
}
