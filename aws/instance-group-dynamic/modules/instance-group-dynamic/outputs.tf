output "security_group_id" {
  description = "The security group used to grant the instances network permissions"
  value = "${aws_security_group.default.id}"
}

output "auto_scaling_name" {
  description = "The name of the auto scaling group created for this instance group"
  value = "${aws_autoscaling_group.main.name}"
}

output "instance_profile" {
  description = "The name of the instance profile for the instances"
  value = "${aws_iam_instance_profile.main.name}"
}

output "instance_profile_role" {
  description = "The name of the role to be used for granting IAM permissions to instance in the group"
  value = "${aws_iam_role.main.name}"
}
