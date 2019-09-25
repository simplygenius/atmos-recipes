locals {
  all_keys = keys(var.account_map)

  in_upstream_only_count                = var.upstream_key == var.current_key ? 1 : 0
  in_each_downstream_count              = var.upstream_key == var.current_key && false == contains(var.downstream_keys, var.upstream_key) ? 0 : 1
  in_upstream_for_each_downstream_count = var.upstream_key == var.current_key ? length(var.downstream_keys) : 0

  in_upstream_aggregate_enablement_count = var.enable_aggregate_group ? local.in_upstream_only_count : 0
  in_upstream_each_key_enablement_count  = var.enable_keyed_groups ? local.in_upstream_only_count : 0
  in_upstream_either_enablement_count = signum(
    local.in_upstream_aggregate_enablement_count + local.in_upstream_each_key_enablement_count,
  )

  upstream_group_names = zipmap(
    var.downstream_keys,
    formatlist("%s-${var.name}", var.downstream_keys),
  )
  downstream_role_names = zipmap(
    var.downstream_keys,
    formatlist("%s-${var.name}", var.downstream_keys),
  )
  aggregate_group_name = "${var.aggregate_group_key}-${var.name}"
}

// The group controlling access to each downstream role
resource "aws_iam_group" "upstream" {
  count = local.in_upstream_for_each_downstream_count * local.in_upstream_each_key_enablement_count

  name = element(values(local.upstream_group_names), count.index)
  path = "/"
}

// The group controlling aggregate access to all of the downstream roles
resource "aws_iam_group" "upstream-aggregate" {
  count = local.in_upstream_aggregate_enablement_count

  name = local.aggregate_group_name
  path = "/"
}

// The policy for assuming role to each downstream role
data "template_file" "policy-upstream-allow-assume-downstream-role" {
  count = length(var.downstream_keys) // so that output works in either stream

  vars = {
    account_id = var.account_map[var.downstream_keys[count.index]]
    role_name  = "${var.downstream_keys[count.index]}-${var.name}"
  }

  template = file(
    "${path.module}/templates/policy-upstream-allow-assume-downstream-role.tmpl.json",
  )
}

// Attach to each upstream group the policy for assuming role to each downstream role
resource "aws_iam_group_policy" "attach-upstream-allow-assume-downstream-role" {
  count = local.in_upstream_for_each_downstream_count * local.in_upstream_each_key_enablement_count

  name   = "allow-assume-role-to-${var.downstream_keys[count.index]}-${var.name}"
  group  = aws_iam_group.upstream[count.index].id
  policy = data.template_file.policy-upstream-allow-assume-downstream-role[count.index].rendered
}

// Attach to the aggregate group all the policies for assuming role to all the downstream roles
resource "aws_iam_group_policy" "attach-aggregate-upstream-allow-assume-downstream-role" {
  count = local.in_upstream_for_each_downstream_count * local.in_upstream_aggregate_enablement_count

  name   = "allow-assume-role-to-${var.downstream_keys[count.index]}-${var.name}"
  group  = aws_iam_group.upstream-aggregate[0].id
  policy = data.template_file.policy-upstream-allow-assume-downstream-role[count.index].rendered
}

// The policy for the downstream role that allows the upstream account to assume it
data "template_file" "policy-downstream-allow-upstream-to-assume-role" {
  vars = {
    upstream_account_id = var.account_map[var.upstream_key]
    require_mfa         = var.require_mfa
  }

  template = file(
    "${path.module}/templates/policy-downstream-allow-upstream-to-assume-role.tmpl.json",
  )
}

// The role for each downstream account
resource "aws_iam_role" "downstream" {
  count = local.in_each_downstream_count

  name                 = local.downstream_role_names[var.current_key]
  path                 = "/"
  assume_role_policy   = data.template_file.policy-downstream-allow-upstream-to-assume-role.rendered
  max_session_duration = var.max_session_duration
}

// The policies containing downstream role permissions, in a template to allow some basic interpolations
data "template_file" "downstream-role-policies" {
  count = local.in_each_downstream_count * length(var.downstream_role_policies)

  vars = {
    upstream_key          = var.upstream_key
    upstream_account_id   = var.account_map[var.upstream_key]
    downstream_key        = var.current_key
    downstream_account_id = var.account_map[var.current_key]
  }

  template = element(values(var.downstream_role_policies), count.index)
}

// Attach to the downstream role each permission policy
resource "aws_iam_role_policy" "attach-downstream-role-policy" {
  count = local.in_each_downstream_count * length(var.downstream_role_policies)

  name = "${var.current_key}-${var.name}-${element(keys(var.downstream_role_policies), count.index)}"
  role = aws_iam_role.downstream[0].name

  policy = data.template_file.downstream-role-policies[count.index].rendered
}

