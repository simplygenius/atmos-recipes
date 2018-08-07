locals {
  instance_group_lock_table = "${var.local_name_prefix}instance-group-lock-table"
  instance_group_lock_key = "LockID"
}

resource "aws_dynamodb_table" "instance-group-lock-table" {
  name = "${local.instance_group_lock_table}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "${local.instance_group_lock_key}"

  attribute {
    name = "${local.instance_group_lock_key}"
    type = "S"
  }

  tags {
    Env = "${var.atmos_env}"
    Source = "atmos"
  }
}
