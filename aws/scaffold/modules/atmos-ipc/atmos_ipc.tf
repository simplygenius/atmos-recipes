variable "action" {
  description = "The IPC action to perform"
}

variable "params" {
  description = "The map of parameters to send to atmos IPC"
  type = "map"
}

variable "enabled" {
  description = "Allows disabling the notification programatically"
  default = 1
}

locals {
  query = "${merge(var.params, map(
    "action", "${var.action}",
    "enabled", "${var.enabled}"
  ))}"
}

data "external" "notify" {
  count = "${signum(var.enabled)}"

  program = ["sh", "-c", "$ATMOS_IPC_CLIENT"]

  query = "${local.query}"
}

output "force_dependency" {
  description = "Allows one to force a dependency on this module completing, e.g. when modal=true"
  value = "${jsonencode(data.external.notify.*.result) == "" ? "" : ""}"
}
