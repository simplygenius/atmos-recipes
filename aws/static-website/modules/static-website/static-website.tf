locals {
  origin_id = "${var.global_name_prefix}${var.name}-origin"
  redirect_origin_id = "${var.global_name_prefix}${var.name}-redirect-origin"

  primary_alias = "${var.aliases[0]}"
  secondary_aliases = "${slice(var.aliases, 1, length(var.aliases))}"
  redirect_aliases = "${compact(split(",", signum(var.redirect_aliases) == 1 ? join(",", local.secondary_aliases) : ""))}"
  cdn_aliases = "${compact(split(",", signum(var.redirect_aliases) == 1 ? local.primary_alias : join(",", var.aliases)))}"
}

resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "To restrict access to the bucket to only cloudfront requests"
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true
  is_ipv6_enabled = true
  price_class = "${var.price_class}"
  aliases = "${local.cdn_aliases}"
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

resource "aws_route53_record" "site" {
  count = "${length(local.cdn_aliases)}"

  zone_id = "${var.zone_id}"
  name = "${local.cdn_aliases[count.index]}"
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

//resource "aws_s3_bucket" "alias_redirects" {
//  count = "${length(local.redirect_aliases)}"
//
//  bucket = "${local.redirect_aliases[count.index]}"
//  acl = "public-read"
//
//  website {
//    redirect_all_requests_to = "https://${local.primary_alias}"
//  }
//}
//
//resource "aws_route53_record" "alias_redirects" {
//  zone_id = "${var.zone_id}"
//  name = "${local.redirect_aliases[count.index]}"
//  type = "A"
//
//  alias {
//    name = "${aws_s3_bucket.alias_redirects.website_domain}"
//    zone_id = "${aws_s3_bucket.alias_redirects.hosted_zone_id}"
//    evaluate_target_health = true
//  }
//}

resource "aws_s3_bucket" "alias_redirects" {
  bucket = "${var.site_bucket}-redirects"
  acl = "public-read"

  website {
    redirect_all_requests_to = "https://${local.primary_alias}"
  }
}

resource "aws_route53_record" "alias_redirects" {
  count = "${length(local.redirect_aliases)}"

  zone_id = "${var.zone_id}"
  name = "${local.redirect_aliases[count.index]}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.alias_redirects.0.domain_name}"
    zone_id = "${aws_cloudfront_distribution.alias_redirects.0.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_distribution" "alias_redirects" {
  count = "${signum(var.redirect_aliases) == 1 ? 1 : 0}"

  enabled = true
  is_ipv6_enabled = true
  price_class = "${var.price_class}"
  aliases = "${local.redirect_aliases}"

  origin {
    domain_name = "${aws_s3_bucket.alias_redirects.website_endpoint}"
    origin_id = "${local.redirect_origin_id}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port = 80
      https_port = 443
      origin_ssl_protocols = [
        "TLSv1.2",
        "TLSv1.1",
        "TLSv1"
      ]
    }
  }

  logging_config {
    include_cookies = false
    bucket = "${var.logs_bucket}.s3.amazonaws.com"
    prefix = "cdn-access-logs/${var.name}-redirects"
  }

  default_cache_behavior {
    allowed_methods = "${var.cdn_allowed_methods}"
    cached_methods = "${var.cdn_cached_methods}"
    target_origin_id = "${local.redirect_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
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
    Name = "${var.local_name_prefix}${var.name}-redirects"
    Environment = "${var.atmos_env}"
    Source = "terraform"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = "${var.certificate_arn}"
    ssl_support_method = "sni-only"
  }
}
