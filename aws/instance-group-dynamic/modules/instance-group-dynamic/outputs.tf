output "security_group_id" {
  description = "The security group used to grant the instances network permissions"
  value = "${aws_security_group.default.id}"
}

output "auto_scaling_name" {
  description = "The name of the auto scaling group created for this instance group"
  value = "${aws_autoscaling_group.main.name}"
}

output "instance_role" {
  description = "The name of the role used for granting IAM permissions to instances in the group"
  value = "${aws_iam_role.main.name}"
}
