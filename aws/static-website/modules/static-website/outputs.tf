output "site_bucket_arn" {
  description = "The arn for the bucket created by this modue for hosting static website data"
  value = "${aws_s3_bucket.site.arn}"
}