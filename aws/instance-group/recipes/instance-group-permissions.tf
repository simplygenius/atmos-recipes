module "instance-group-iam-inspect-for-ssh" {
  source = "../modules/cross-account-role"

  atmos_env = "${var.atmos_env}"
  global_name_prefix = "${var.global_name_prefix}"
  local_name_prefix = "${var.local_name_prefix}"
  account_ids = "${var.account_ids}"
  name = "instance-group-iam-inspect-for-ssh"

  upstream_env = "${local.ops_env}"
  downstream_envs = "${local.envs_without_ops}"

  policy = <<POLICY
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListGroups",
        "iam:ListGroupsForUser",
        "iam:ListGroupPolicies",
        "iam:GetGroup",
        "iam:ListSshPublicKeys",
        "iam:GetSshPublicKey"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

locals {
  // A map indicating which iam groups in the ops account grant users access on instances
  iam_permission_groups = {
    account = ["ops-admin", "${var.atmos_env}-admin"]
    ssh = ["ops-admin", "${var.atmos_env}-admin"]
    sudo = ["ops-admin", "${var.atmos_env}-admin"]
  }
}
