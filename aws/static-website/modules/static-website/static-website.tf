locals {
  origin_id = "${var.global_name_prefix}${var.name}-origin"
  redirect_origin_id = "${var.global_name_prefix}${var.name}-redirect-origin"

  primary_alias = "${var.aliases[0]}"
  secondary_aliases = "${slice(var.aliases, 1, length(var.aliases))}"
}

resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "To restrict access to the bucket to only cloudfront requests"
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true
  is_ipv6_enabled = true
  price_class = "${var.price_class}"
  aliases = "${var.aliases}"
  default_root_object = "${var.index_page}"

  origin {
    domain_name = "${aws_s3_bucket.site.bucket_domain_name}"
    origin_id = "${local.origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.site.cloudfront_access_identity_path}"
    }
  }

  custom_error_response {
    error_code = 404
    response_code = 404
    response_page_path = "${var.error_page_404}"
  }

  logging_config {
    include_cookies = false
    bucket = "${var.logs_bucket}.s3.amazonaws.com"
    prefix = "cdn-access-logs/${var.name}"
  }

  default_cache_behavior {
    allowed_methods = "${var.cdn_allowed_methods}"
    cached_methods = "${var.cdn_cached_methods}"
    target_origin_id = "${local.origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = "${aws_lambda_function.site-redirects.qualified_arn}"
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
    compress = "${var.compress}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    Name = "${var.local_name_prefix}${var.name}"
    Environment = "${var.atmos_env}"
    Source = "terraform"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = "${var.certificate_arn}"
    ssl_support_method = "sni-only"
  }
}


resource "aws_iam_role" "site-redirects-lambda" {
  name = "${var.local_name_prefix}${var.name}-site-redirects"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "site-redirects-lambda" {
  role = "${aws_iam_role.site-redirects-lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "template_file" "site-redirects-lambda" {
  template = "${file("${path.module}/lambda-redirect.tmpl.js")}"

  vars {
    primary_alias = "${local.primary_alias}"
    default_root_object = "${var.index_page}"
    enable_deep_default_objects = "${var.enable_deep_default_objects == 1 ? "true" : "false"}"
    enable_redirects = "${var.enable_redirects == 1 ? "true" : "false"}"
  }
}

data "archive_file" "site-redirects-lambda" {
  type = "zip"

  source_content = "${data.template_file.site-redirects-lambda.rendered}"
  source_content_filename = "main.js"
  output_path = "${path.root}/tmp/lambda-redirect.zip"
}

resource "aws_lambda_function" "site-redirects" {
  function_name = "${var.local_name_prefix}${var.name}_cdn_redirect"
  filename = "${data.archive_file.site-redirects-lambda.output_path}"
  source_code_hash = "${data.archive_file.site-redirects-lambda.output_base64sha256}"
  publish = true

  role = "${aws_iam_role.site-redirects-lambda.arn}"
  handler = "main.handler"
  runtime = "nodejs8.10"
}

resource "aws_route53_record" "site" {
  count = "${length(var.aliases)}"

  zone_id = "${var.zone_id}"
  name = "${var.aliases[count.index]}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.site.domain_name}"
    zone_id = "${aws_cloudfront_distribution.site.hosted_zone_id}"
    evaluate_target_health = false
  }
}

data "aws_iam_policy_document" "site-cloudfront-s3-access" {
  statement {
    actions = [
      "s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.site_bucket}/*"]

    principals {
      type = "AWS"
      identifiers = [
        "${aws_cloudfront_origin_access_identity.site.iam_arn}"]
    }
  }

  statement {
    actions = [
      "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.site_bucket}"]

    principals {
      type = "AWS"
      identifiers = [
        "${aws_cloudfront_origin_access_identity.site.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.site_bucket}"
  acl = "private"

  cors_rule {
    allowed_headers = "${var.cors_allowed_headers}"
    allowed_methods = "${var.cors_allowed_methods}"
    allowed_origins = "${var.cors_allowed_origins}"
    max_age_seconds = "${var.cors_max_age_seconds}"
  }

  policy = "${data.aws_iam_policy_document.site-cloudfront-s3-access.json}"
}
