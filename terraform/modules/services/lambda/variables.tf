variable "lambdas" {
  type = map(any)
}

variable "lambda_subnet_ids" {
  type = list(any)
}

variable "lambda_security_group_ids" {
  type = list(any)
}

variable "lambda_role_arn" {
  type = string
}
variable "lambda_layers" {
  type = map(any)
}

variable "lambda_permissions" {
  type = list(any)
}
# variable "kms_keys" {
#   type = map(any)
# }

# variable "user_pool_arns" {
#   type = map(any)
# }

# variable "appsync_url" {
#   type = string
# }

variable "sqs_arns" {
  type = map(any)
}

variable "lambda_event_source_mapping" {
  type = map(any)
}

variable "tags" {
  type = map(string)
}
