output "rendered" {
  description = "The rendered user data in a form suitable for passing to resources that need it (cloudinit config)"
  value = local.user_data_bucket_enablement == 0 ? module.user-data-framework.rendered : join(
    "",
    data.template_cloudinit_config.user-data-bucket.*.rendered,
  )
}

output "user_data_dir" {
  description = <<-EOF
    The directory where custom user data files can be written, and they will be run in directory order as part of
    user-data process at first boot
EOF


  value = module.user-data-framework.user_data_dir
}

