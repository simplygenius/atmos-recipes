output "config" {
  description = "Cloudinit config to support the files produced by this module for use in user-data"
  value       = data.template_file.bootstrap_cloudinit.rendered
}

output "policies" {
  description = "IAM Policies required by the files produced by this module, typically attached to an instance role (list of maps with name, policy keys)"
  value       = data.null_data_source.policies.*.outputs
}

output "policy_count" {
  description = "Count of IAM Policies"
  value       = length(local.policy_names)
}

output "files" {
  description = "The files generated by this module for use in user-data"
  value       = local.files
}

output "environment" {
  description = "Environment variables needed by user data scripts"
  value = {
    ATMOS_NAME = var.name
    ZONE_ID    = var.zone_id
    DOMAIN     = replace(data.aws_route53_zone.zone.name, "/\\.$/", "")
    LOCK_TABLE = var.lock_table
    LOCK_KEY   = var.lock_key
    ZONE_IP    = var.use_public_ip ? "$INSTANCE_PUBLIC_IP" : "$INSTANCE_PRIVATE_IP"
  }
}

