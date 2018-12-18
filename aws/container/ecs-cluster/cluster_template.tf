resource "aws_ecs_cluster" "<%= name %>" {
  name = "${var.local_name_prefix}<%= name %>"
}
