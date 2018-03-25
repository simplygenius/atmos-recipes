output "registry_host" {
  value = "${join("", aws_ecr_repository.main.*.registry_id)}.dkr.ecr.${var.region}.amazonaws.com"
}

output "repository_name" {
  value = "${join("", aws_ecr_repository.main.*.name)}"
}

output "log_group" {
  value = "${aws_cloudwatch_log_group.main.name}"
}

output "port" {
  value = "${var.port}"
}

output "task_role" {
  value = "${aws_iam_role.ecs-task.name}"
}

output "security_group_id" {
   value = "${aws_security_group.default.id}"
}
