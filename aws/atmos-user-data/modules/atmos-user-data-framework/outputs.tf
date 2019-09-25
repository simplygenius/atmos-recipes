output "rendered" {
  description = "The rendered user data in a form suitable for passing to resources that need it (cloudinit config)"
  value       = data.template_cloudinit_config.user-data.rendered
}

output "user_data_dir" {
  description = <<-EOF
    The directory where custom user data files can be written, and they will be run in directory order as part of
    user-data process at first boot
EOF


  value = var.user_data_dir
}

