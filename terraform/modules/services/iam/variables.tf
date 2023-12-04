
#IAM
variable "lambda_role_name" {
  type = string
}

variable "api_gateway_role_name" {
  type = string
}

# variable "appsync_service_role_name" {
#   type = string
# }

# variable "appsync_cloudwatch_role_name" {
#   type = string
# }

# variable "subscription_table_name" {
#   type = string
# }

variable "dynamodb_table_arns" {
  type = list
}

variable "eventbridge_scheduler_role" {
  type = string
}