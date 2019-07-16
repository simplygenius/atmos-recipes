output "security_group_id" {
   value = "${aws_security_group.default.id}"
}

output "user_data_config" {
  value = <<EOF
packages:
  - nfs-common

mounts:
  - [ "${aws_efs_file_system.primary.id}.efs.${var.region}.amazonaws.com:/", "/efs", "nfs", "nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" ]
EOF
}
