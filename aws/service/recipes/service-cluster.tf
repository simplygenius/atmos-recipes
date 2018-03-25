resource "aws_ecs_cluster" "services" {
  name = "${var.local_name_prefix}services"
}
