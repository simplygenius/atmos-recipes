output "security_group_id" {
  description = "The security group used to grant network permissions"
  value       = aws_security_group.default.id
}

output "mount_point" {
  description = "Convenience referencing the input variable mount_point"
  value       = var.mount_point
}

output "cloudinit_config" {
  description = "Convenience supplying the cloudinit config that causes ec2 instances to mount this efs filesystem"
  value       = <<EOF
packages:
  - nfs-common

mounts:
  - [ "${aws_efs_file_system.primary.dns_name}:/", "#{var.mount_point}", "nfs", "nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" ]
EOF

}

