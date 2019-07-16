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

variable "region" {
  description = "The aws region"
}

variable "acl" {
  description = "The access control setting"
  default = "private"
}

variable "logs_bucket" {
  description = "For s3 access logs"
}

variable "force_destroy_buckets" {
  description = "Force destroy S3 buckets, even if they have some data"
  default = 0
}

variable "bucket_policy_template" {
  description = <<-EOF
    Override the default bucket policy which enforces encryption - if you want
    to continue enforcing encryption, you can do so with a policy that
    references $${enforce_encryption_statements}
  EOF
  default = ""
}

variable "enforce_encryption" {
  description = "Sets up bucket policy to enforce encryption using the given scheme: none, aes, kms"
  default = ""
}

variable "versioning" {
  description = "Enables bucket versioning"
  default = "false"
}

variable "versioning_transition_days" {
  description = "Number of days before transitioning non-current versions to reduced redundancy storage"
  default = 90
}

variable "versioning_expiration_days" {
  description = "Number of days before expiring non-current versions"
  default = 365
}

variable "tags" {
  description = "Tags assigned to the bucket"
  default = {}
  type = "map"
}
