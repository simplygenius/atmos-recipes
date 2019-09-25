resource "aws_security_group" "default" {
  name   = "${var.local_name_prefix}elasticsearch-${var.name}"
  vpc_id = var.vpc_id
}

data "aws_caller_identity" "current" {
}

// double-dollar in variable default declaration doesn't work properly
// https://github.com/hashicorp/terraform/issues/18069
data "template_file" "access_policy_dummy" {
  template = var.access_policy_template
}

data "template_file" "access_policy" {
  template = data.template_file.access_policy_dummy.rendered

  vars = {
    account_id  = data.aws_caller_identity.current.account_id
    domain_name = aws_elasticsearch_domain.main.domain_name
  }
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name     = aws_elasticsearch_domain.main.domain_name
  access_policies = chomp(data.template_file.access_policy.rendered)
}

resource "aws_iam_service_linked_role" "main" {
  aws_service_name = "es.amazonaws.com"
}

locals {
  is_zoned     = lookup(var.cluster_config, "zone_awareness_enabled", false)
  subnet_count = local.is_zoned ? length(var.subnet_ids) : 1
}

resource "aws_elasticsearch_domain" "main" {
  depends_on = [aws_iam_service_linked_role.main]

  domain_name           = "${var.local_name_prefix}${var.name}"
  elasticsearch_version = var.elasticsearch_version

  vpc_options {
    subnet_ids         = slice(var.subnet_ids, 0, local.subnet_count)
    security_group_ids = [aws_security_group.default.id, var.security_groups]
  }

  dynamic "cluster_config" {
    for_each = [var.cluster_config]
    content {
      dedicated_master_count   = lookup(cluster_config.value, "dedicated_master_count", null)
      dedicated_master_enabled = lookup(cluster_config.value, "dedicated_master_enabled", null)
      dedicated_master_type    = lookup(cluster_config.value, "dedicated_master_type", null)
      instance_count           = lookup(cluster_config.value, "instance_count", null)
      instance_type            = lookup(cluster_config.value, "instance_type", null)
      zone_awareness_enabled   = lookup(cluster_config.value, "zone_awareness_enabled", null)

      dynamic "zone_awareness_config" {
        for_each = lookup(cluster_config.value, "zone_awareness_config", [])
        content {
          availability_zone_count = lookup(zone_awareness_config.value, "availability_zone_count", null)
        }
      }
    }
  }

  advanced_options = var.advanced_options

  dynamic "ebs_options" {
    for_each = [var.ebs_options]
    content {
      ebs_enabled = ebs_options.value.ebs_enabled
      iops        = lookup(ebs_options.value, "iops", null)
      volume_size = lookup(ebs_options.value, "volume_size", null)
      volume_type = lookup(ebs_options.value, "volume_type", null)
    }
  }

  dynamic "snapshot_options" {
    for_each = [var.snapshot_options]
    content {
      automated_snapshot_start_hour = snapshot_options.value.automated_snapshot_start_hour
    }
  }
}

resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = format(var.host_format, var.name)
  type    = "CNAME"
  ttl     = "300"

  records = [
    aws_elasticsearch_domain.main.endpoint,
  ]
}

