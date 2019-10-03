output "registry_host" {
  description = "The host name for the ECR registry"
  value       = "${join("", aws_ecr_repository.main.*.registry_id)}.dkr.ecr.${var.region}.amazonaws.com"
}

output "repository_name" {
  description = "The name of the image in the ECR registry"
  value       = join("", aws_ecr_repository.main.*.name)
}

output "log_group" {
  description = "The name of the log group that the service logs to"
  value       = aws_cloudwatch_log_group.main.name
}

output "port" {
  description = "The port the service listens on"
  value       = var.port
}

output "task_role" {
  description = "The role used to grant the service IAM permissions"
  value       = aws_iam_role.ecs-task.name
}

output "execution_role" {
  description = "The role used to grant the service execution framework IAM permissions"
  value       = aws_iam_role.ecs-execution.name
}

output "security_group_id" {
  description = "The security group used to grant the service network permissions"
  value       = aws_security_group.default.id
}

output "service_name" {
  description = "The service_name"
  value       = concat(aws_ecs_service.with_autoscale.*.name, aws_ecs_service.without_autoscale.*.name)[0]
}
