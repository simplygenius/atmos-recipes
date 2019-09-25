variable "atmos_env" {
  description = "The atmos environment"
}

variable "global_name_prefix" {
  description = <<-EOF
    The global name prefix for disambiguating resource names that have a global
    scope (e.g. s3 bucket names)
EOF


  default = ""
}

variable "local_name_prefix" {
  description = <<-EOF
    The local name prefix for disambiguating resource names that have a local scope
    (e.g. when running multiple environments in the same account)
EOF


  default = ""
}

variable "name" {
  description = "The component name"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "zone_id" {
  description = "The zone id for registering the endpoint - can be public or private"
}

variable "subnet_ids" {
  description = "The subnet ids for components that need them - can be public or private"
  type        = list(string)
}

variable "security_groups" {
  description = "The security groups associated with the instance"
  type        = list(string)
}

variable "host_format" {
  description = <<EOF
    The format used to register the friendly hostname in route53 -
    the formatter is passed the component name
  
EOF


  default = "%s-es"
}

variable "instance_type" {
  description = "Instance size"
  default     = "single-az"
}

variable "elasticsearch_version" {
  description = "The elasticsearch version"
  default     = "5.0"
}

variable "parameter" {
  description = "The parameters for the instance's parameter group"
  type        = list(string)
  default     = []
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default     = ""
}

variable "cluster_config" {
  description = "The cluster config map"
  type        = map(string)
  default     = {}
}

variable "advanced_options" {
  description = "The advanced options map"
  type        = map(string)
  default     = {}
}

variable "ebs_options" {
  description = "The ebs options map"
  type        = map(string)
  default = {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 100
  }
}

variable "snapshot_options" {
  description = "The snapshot options map"
  type        = map(string)
  default = {
    automated_snapshot_start_hour = 2
  }
}

variable "access_policy_template" {
  description = "The access policy"
  default     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:us-east-1:$$${account_id}:domain/$$${domain_name}/*"
    }
  ]
}
EOF

}

