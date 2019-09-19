output "site_bucket_arn" {
  description = "The arn for the bucket created by this module for hosting static website data"
  value = "${aws_s3_bucket.site.arn}"
}

output "distribution_id" {
  description = "The cloudfront distribution id"
  value = "${aws_cloudfront_distribution.site.id}"
}

output "distribution_arn" {
  description = "The cloudfront distribution arn"
  value = "${aws_cloudfront_distribution.site.arn}"
}
