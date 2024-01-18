output "account_id" {
  value = data.aws_caller_identity.current.account_id
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ aws_s3_bucket_state
output "aws_s3_bucket_state" {
  value = aws_s3_bucket.state
}
