output "registry_host" {
  description = "The host name for the ECR registry"
  value = "${join("", aws_ecr_repository.main.*.registry_id)}.dkr.ecr.${var.region}.amazonaws.com"
}

output "repository_name" {
  description = "The name of the image in the ECR registry"
  value = "${join("", aws_ecr_repository.main.*.name)}"
}

output "log_group" {
  description = "The name of the log group that tasks log to"
  value = "${aws_cloudwatch_log_group.main.name}"
}

output "task_role" {
  description = "The role used to grant the task IAM permissions"
  value = "${aws_iam_role.ecs-task.name}"
}
