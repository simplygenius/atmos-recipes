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

variable "force_destroy_buckets" {
  description = <<-EOF
    Allows destruction of s3 buckets that have contents.  Set to true for
    error-free destroys, but should be false for day to day usage.  Note you
    need to apply with it set to true in order for it to take effect in a
    destroy.  e.g.
      TF_VAR_force_destroy_buckets=true atmos apply
      TF_VAR_force_destroy_buckets=true atmos destroy
EOF


  default = false
}

variable "name" {
  description = "The component name"
}

variable "aliases" {
  description = "The hostname aliases for the website"
  type        = list(string)
}

variable "zone_id" {
  description = "The zone to register the hostname for the cdn"
}

variable "certificate_arn" {
  description = "The certificate for ssl for the website"
}

variable "site_bucket" {
  description = "The bucket containing the website"
}

variable "logs_bucket" {
  description = "The bucket to hold website access logs"
}

variable "enable_redirects" {
  description = "Adds an http redirect for secondary aliases (1..-1) to the primary alias (0)"
  default     = 1
}

variable "enable_deep_default_objects" {
  description = "Allows requests to subdirectories to get rewritten to the subdir/index_page"
  default     = 1
}

variable "cdn_allowed_methods" {
  description = "The http methods to allow"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cdn_cached_methods" {
  description = "The http methods to cache"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_methods" {
  description = "The http methods to allow for the CORS rule"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_headers" {
  description = "The http headers to allow for the CORS rule"
  type        = list(string)
  default     = ["Authorization"]
}

variable "cors_allowed_origins" {
  description = "The origins to allow for the CORS rule"
  type        = list(string)
  default     = ["*"]
}

variable "cors_max_age_seconds" {
  description = "The age for the CORS rule"
  default     = 3000
}

variable "price_class" {
  description = "The page for serving http index"
  default     = "PriceClass_200"
}

variable "compress" {
  description = "Turnn on compression of assets if browse accepts gzip"
  default     = "true"
}

variable "index_page" {
  description = "The page for serving http index"
  default     = "index.html"
}

variable "error_page_404" {
  description = "The page for serving 404 errors"
  default     = "/404.html"
}

