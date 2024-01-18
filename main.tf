provider "aws" {
  region  = "eu-central-1"
}

data "aws_caller_identity" "current" {}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ aws_dynamodb_table state_lock
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # The table must have a primary key named LockID.
  # See below for more detail.
  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  lock_key_id = "LockID"
}

resource "aws_dynamodb_table" "state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = var.dynamodb_table_billing_mode
  hash_key     = local.lock_key_id

  attribute {
    name = local.lock_key_id
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ aws_s3_bucket - state_bucket
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "state_bucket" {
  bucket = format("%s-%s", var.state_bucket_prefix, data.aws_caller_identity.current.account_id)
}

resource "aws_s3_bucket_acl" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "state_bucket_force_ssl" {
  depends_on = [aws_s3_bucket_public_access_block.state]
  bucket     = aws_s3_bucket.state_bucket.id
  policy     = data.aws_iam_policy_document.state_bucket_force_ssl.json
}

data "aws_iam_policy_document" "state_bucket_force_ssl" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.state_bucket.arn,
      "${aws_s3_bucket.state_bucket.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
