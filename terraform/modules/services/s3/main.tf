resource "aws_s3_bucket" "bucket" {
  for_each = var.s3_buckets

  bucket = each.value.name

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    },
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption_configuration" {
  for_each = var.s3_buckets
  bucket   = each.value.name
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = each.value.kms_key != "" ? var.kms_keys[var.s3_buckets[each.key].kms_key] : ""
      sse_algorithm     = each.value.kms_key != "" ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  for_each = var.s3_buckets
  bucket   = each.value.name
  acl      = each.value.acl
}

data "aws_lambda_function" "notification_function" {
  for_each = {
    for name, bucket in var.s3_buckets : name => bucket
    if bucket.should_trigger_lambda == true
  }
  function_name = each.value.lambda_name
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = {
    for name, bucket in var.s3_buckets : name => bucket
    if bucket.should_trigger_lambda == true
  }

  bucket = each.value.name

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.notification_function[each.value.lambda_name]
    events              = each.value.events
    filter_prefix       = each.value.filter_prefix
    filter_suffix       = each.value.filter_suffix
  }

  depends_on = [
    data.aws_lambda_function.notification_function
  ]
}

resource "aws_lambda_permission" "allow_bucket" {
  for_each = {
    for name, bucket in var.s3_buckets : name => bucket
    if bucket.should_trigger_lambda == true
  }

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket[each.key].arn
}
