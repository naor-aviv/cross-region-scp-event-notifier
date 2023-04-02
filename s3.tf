locals {
  bucket_name       = "${var.function_name}-${data.aws_caller_identity.current.account_id}"
}

module "lambda_s3_bucket" {
  count = var.create_cloudtrail_trail ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.6"

  bucket = local.bucket_name
  acl    = "private"

  # Bucket policies
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

# Copy Python script
resource "null_resource" "copy_python" {
  provisioner "local-exec" {
    command = "cp ${var.script_name}-old.py ${var.script_name}.py"
  }
}

resource "aws_s3_object" "lambda_package" {
  bucket = module.lambda_s3_bucket.s3_bucket_id
  key    = "${var.script_name}.zip"
  source = "./${var.script_name}.zip"
}


data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.current.id]
    }

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }
}
