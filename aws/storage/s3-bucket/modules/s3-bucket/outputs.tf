output "bucket" {
  description = "The actual bucket name"

  //value = "${aws_s3_bucket.bucket.bucket}"
  value = local.bucket_name
}

output "region" {
  description = "The region for the bucket"
  value       = var.region
}

