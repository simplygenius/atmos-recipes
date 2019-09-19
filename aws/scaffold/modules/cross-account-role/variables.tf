variable "name" {
  description = "The name to use for creating groups/roles"
}

variable "upstream_key" {
  description = <<-EOF
    The key selecting the upstream account from account_map.  This account will
    get the group granting access to the roles in the downstream account
  EOF
}

variable "downstream_keys" {
  description = <<-EOF
    The keys selecting the downstream accounts from account_map.  These accounts
    will get the role with given policies attached and allow access from the
    upstream account.
  EOF
  type = "list"
}

variable "current_key" {
  description = <<-EOF
    The current key.  Used to trigger which side of the upstream/downstream
    recipes get triggered.
  EOF
}

variable "account_map" {
  description = "The map of keys -> account_ids"
  type = "map"
}

variable "downstream_role_policies" {
  description = <<-EOF
    The policies to be attached to the downstream role.  The keys are friendly
    names for each value policy.  The policy will be evaluated as a template
    with values supplied for upstream_key, upstream_account_id, downstream_key,
    downstream_account_id
  EOF
  type = "map"
  default = {}
}

variable "enable_keyed_groups" {
  description = <<-EOF
    Creates an upstream group for each downstream key to allow maximum
    flexibility in assigning access to users
  EOF
  default = true
}

variable "enable_aggregate_group" {
  description = <<-EOF
    Creates a single upstream group that grants access to all downstream roles
    for convenience in granting users full access
  EOF
  default = true
}

variable "aggregate_group_key" {
  description = "Provides the key for the aggregate group"
  default = "super"
}

variable "require_mfa" {
  description = <<-EOF
    Forces the downstream role to require MFA be present for the identity
    requesting to assume it
  EOF
  default = false
}

variable "max_session_duration" {
  description = <<-EOF
    Set the max session duration on the downstream role
  EOF
  default = 3600
}
