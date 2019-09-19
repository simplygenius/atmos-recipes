output "upstream_group_names" {
  description  = "Maps key -> the group_names that are created in the upstream account that grant access to each downstream role"
  value = "${local.upstream_group_names}"
}

output "upstream_aggregate_group_name" {
  description  = "The group name for the aggregate group created in the upstream account that grants access to all of the downstream roles"
  value = "${local.aggregate_group_name}"
}

output "upstream_group_policies" {
  description  = "Maps key -> the policy strings that are created in the upstream account that grant access to each downstream role"
  value = "${zipmap(var.downstream_keys, data.template_file.policy-upstream-allow-assume-downstream-role.*.rendered)}"
}

output "downstream_role_names" {
  description  = "Maps key -> the role_names that are created in each downstream account"
  value = "${local.downstream_role_names}"
}

output "in_upstream_only_count" {
  description  = "Provides a count of 0/1 to allow you to use this output to choose if a resource gets created when running for upstream"
  value = "${local.in_upstream_only_count}"
}

output "in_each_downstream_count" {
  description  = "Provides a count of 0/1 to allow you to use this output to choose if a resource gets created when running for downstream"
  value = "${local.in_each_downstream_count}"
}
