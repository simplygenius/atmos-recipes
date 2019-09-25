output "rendered" {
  description = "The rendered cloudinit config yml containing the files specified when calling this module"
  value       = data.template_file.cloudinit-write-files-config.rendered
}

