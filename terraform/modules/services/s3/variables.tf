variable "s3_buckets" {
  type = map(object({
    name    = string,
    acl     = string,
    # kms_key = string,

    # For S3 event notifications
    should_trigger_lambda = bool
    lambda_name           = string
    events                = list(string)
    filter_prefix         = string
    filter_suffix         = string
  }))
}

# variable "kms_keys" {
#   type = map(any)
# }

variable "lambda_arns" { }

variable "tags" {
  type = map(string)
}
