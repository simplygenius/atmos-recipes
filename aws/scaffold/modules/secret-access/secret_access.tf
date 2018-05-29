variable "secret_bucket" {
  description = "The secret bucket name"
}

variable "role" {
  description = "The role to grant secret access to"
}

variable "keys" {
  description = "The secret keys to allow access for"
  type = "list"
}


data "template_file" "secret-access-policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": ${jsonencode(formatlist("arn:aws:s3:::${var.secret_bucket}/%s", var.keys))}
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "secret-access" {
  name = "secret-access"
  role = "${var.role}"

  policy = "${data.template_file.secret-access-policy.rendered}"
}
