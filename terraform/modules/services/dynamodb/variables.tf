variable "dynamodb_tables" {
  type        = list(any)
}

# variable "kms_keys" {
#   type    = map(string)
# }

variable "tags" {
  type    = map(string)
}