output "upstream_role" {
  description = "The name of the upstream role"
  value = "${local.upstream_role_name}"
}

output "downstream_policy" {
  description = "The policy to be attached to roles in the downstream accounts to give them access to upstream role"
  value = "${data.template_file.downstream-policy.rendered}"
}
