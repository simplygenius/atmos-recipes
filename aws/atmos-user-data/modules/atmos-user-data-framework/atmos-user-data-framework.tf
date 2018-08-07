data "template_file" "environment" {
  template = <<EOF
export PATH=/opt/atmos/bin:$PATH
export ATMOS_ENV="${var.atmos_env}"
export GLOBAL_NAME_PREFIX="${var.global_name_prefix}"
export LOCAL_NAME_PREFIX="${var.local_name_prefix}"
export ALARM_TARGET="${var.cloudwatch_alarm_target}"
export INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
export INSTANCE_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
export INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export AWS_ACCOUNT=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="accountId" : ")[^"]*(?=")')
export AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
export AWS_DEFAULT_REGION=$(echo $AVAILABILITY_ZONE | sed -e 's/[a-z]$//')
export USER_DATA_DIR="${var.user_data_dir}"
export USER_DATA_LOG_DIR="${var.user_data_log_dir}"
export DEBUG_USER_DATA="${var.debug_user_data}"
${join("\n", formatlist("export %s=\"%s\"\n", keys(var.additional_environment), values(var.additional_environment)))}
EOF
}

data "template_file" "bootstrap-cloudinit" {
  template = "${file("${path.module}/templates/bootstrap.tmpl.yml")}"
  vars {
    upgrade_packages = "${var.upgrade_packages ? "true" : "false"}"
  }
}

locals {
  implicit_user_data_files = [
    {
      path = "${var.user_data_wrapper}"
      content = "${file("${path.module}/templates/user_data_wrapper.sh")}"
      owner = "root:root"
      permissions = "0755"
    },
    {
      path = "${var.user_data_dir}/99-additional_user_data"
      content = "${var.additional_user_data}"
      owner = "root:root"
      permissions = "0755"
    },
    {
      path = "/etc/profile.d/atmos_env.sh"
      content = "${data.template_file.environment.rendered}"
      owner = "root:root"
      permissions = "0755"
    }
  ]
  user_data_files = "${concat(local.implicit_user_data_files, var.additional_user_data_files)}"

}

module "user-data-files" {
  source = "../../modules/cloudinit-files"
  files = "${local.user_data_files}"
}

data "template_cloudinit_config" "user-data" {
  gzip = "true"
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.bootstrap-cloudinit.rendered}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content = "${var.cloudinit_config}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content = "${var.additional_cloudinit_config}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content = "${module.user-data-files.rendered}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/x-shellscript"
    content = <<EOF
#!/usr/bin/env bash
[[ -f "${var.user_data_wrapper}" && -x "${var.user_data_wrapper}" ]] && "${var.user_data_wrapper}"
EOF
  }
}
