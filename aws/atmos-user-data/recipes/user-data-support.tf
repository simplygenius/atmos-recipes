locals {
  user_data_bucket = "${var.global_name_prefix}user-data"
}

// Cloud-init has the ability to pull data from a url, so we setup a s3 bucket
// here to allow us to put user data in there, and have the instance fetch it at
// boot time.  This is mostly useful for user-data that exceeds the max size,
// but can also be useful if you don't want terraform to recreate instances on
// user data changes (since the url is static for any instance group, even
// though the contents change on s3).  To allow unauthenticated http fetches of
// the data from within cloudinit,  we configure the s3 bucket to allow fetches
// from within the vpc, thus you should ensure that user-data doesn't contain
// anything sensitive (use the
// secrets store!)
//
resource "aws_s3_bucket" "user-data" {
  bucket = local.user_data_bucket
  acl    = "private"

  tags = {
    Env    = var.atmos_env
    Source = "atmos"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUnauthenticatedReadInVPCForUserData",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${local.user_data_bucket}/*",
      "Condition": {
         "StringEquals": {"aws:sourceVpc": ["${module.vpc.vpc_id}"] }
      }
    }
  ]
}
EOF


  tags = {
    Env    = var.atmos_env
    Source = "atmos"
  }
}

// The restriction to allow reads only from a sourceVpc requires s3 to have a
// vpc endpoint
resource "aws_vpc_endpoint" "endpoint" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = flatten([
    module.vpc.public_route_table_ids,
    module.vpc.private_route_table_ids,
  ])
}

