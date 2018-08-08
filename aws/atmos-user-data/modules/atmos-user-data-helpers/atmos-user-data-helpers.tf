data "aws_route53_zone" "zone" {
  zone_id = "${var.zone_id}"
}

data "template_file" "bootstrap_cloudinit" {
  template = "${file("${path.module}/templates/bootstrap.yml")}"
}

data "template_file" "cloudwatch_agent_config" {
  template = "${var.cloudwatch_agent_config != "" ? var.cloudwatch_agent_config : file("${path.module}/templates/cloudwatch_agent_config.tmpl.json")}"

  vars {
    global_name_prefix = "${var.global_name_prefix}"
    local_name_prefix = "${var.local_name_prefix}"
    atmos_env = "${var.atmos_env}"
    name = "${var.name}"
  }
}

data "template_file" "sync_iam_users" {
  template = "${file("${path.module}/templates/sync_iam_users.tmpl.sh")}"
  vars {
    ops_account="${var.account_ids["ops"]}"
    iam_inspect_role="${var.iam_inspect_role}"
    lookup_iam_users_args = "${join(" ", concat(
        formatlist("-g %s", var.iam_permission_groups["account"]),
        formatlist("-s %s", var.iam_permission_groups["ssh"]),
        formatlist("-u %s", var.iam_permission_groups["sudo"])
      ))}"
    }
}

locals {
  policies = [
    {
      name = "${var.local_name_prefix}${var.name}-set-name-tag"
      policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "ec2:CreateTags",
        "sdb:ListDomains",
        "sdb:CreateDomain",
        "sdb:PutAttributes",
        "sdb:GetAttributes",
        "sdb:DeleteAttributes"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
    },
    {
      name = "${var.local_name_prefix}${var.name}-update-route53"
      policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${var.zone_id}"
    }
  ]
}
POLICY
    },
    {
      name = "${var.local_name_prefix}${var.name}-update-ses"
      policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ses:SendRawEmail"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
    },
    {
      name = "${var.local_name_prefix}${var.name}-update-dynamodb-lock-table"
      policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/${var.lock_table}"
    }
  ]
}
POLICY
    },
    {
      name = "${var.local_name_prefix}${var.name}-cloudwatch-agent"
      policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
      },
      {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }
  ]
}
POLICY
    }
  ]

  files = [
    {
      path = "${var.user_data_dir}/5-install_gems"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/user_data.d/install_gems")}"
    },


    {
      path = "/opt/atmos/bin/reserve_name.rb"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/reserve_name.rb")}"
    },
    {
      path = "/etc/init/route53-add.conf"
      owner = "root:root"
      permissions = "0644"
      content = "${file("${path.module}/templates/route53-add.conf")}"
    },
    {
      path = "/etc/init/route53-remove.conf"
      owner = "root:root"
      permissions = "0644"
      content = "${file("${path.module}/templates/route53-remove.conf")}"
    },
    {
      path = "/opt/atmos/bin/update_route53.rb"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/update_route53.rb")}"
    },
    {
      path = "${var.user_data_dir}/10-set_hostname"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/user_data.d/set_hostname")}"
    },


    {
      path = "/opt/atmos/config/amazon-cloudwatch-agent.json"
      owner = "root:root"
      permissions = "0644"
      content = "${data.template_file.cloudwatch_agent_config.rendered}"
    },
    {
      path = "${var.user_data_dir}/15-install_cloudwatch_agent"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/user_data.d/install_cloudwatch_agent")}"
    },


    {
      path = "/opt/atmos/bin/assume_role.rb"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/assume_role.rb")}"
    },
    {
      path = "/opt/atmos/bin/lookup_iam_users.rb"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/lookup_iam_users.rb")}"
    },
    {
      path = "/opt/atmos/bin/update_iam_users.rb"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/update_iam_users.rb")}"
    },
    {
      path = "/opt/atmos/bin/sync_iam_users.sh"
      owner = "root:root"
      permissions = "0755"
      content = "${data.template_file.sync_iam_users.rendered}"
    },
    {
      path = "/etc/cron.hourly/sync_iam_users"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/sync_iam_users.cron")}"
    },
    {
      path = "${var.user_data_dir}/20-sync_iam_users"
      owner = "root:root"
      permissions = "0755"
      content = "${file("${path.module}/templates/user_data.d/sync_iam_users")}"
    },
  ]
}
