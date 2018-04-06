variable "skip_final_snapshot" {
  description = "Flag to turn off the final snapshot on destruction of rds instances"
  default = "false"
}

resource "aws_ecs_cluster" "services" {
  name = "${var.local_name_prefix}services"
}
