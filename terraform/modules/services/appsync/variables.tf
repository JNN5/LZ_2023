variable "appsync" {
    type = any
}

variable "appsync_datasources" {
    type = map(any)
}

variable "appsync_functions" {
    type = map(any)
}

variable "appsync_service_role_arn" {
    type = string
}

variable "appsync_resolvers" {
    type = any
}

variable "lambda_arns" {
    type = map(any)
}

variable "user_pool_ids" {
    type = map(any)
}

variable "appsync_cloudwatch_role_arn" {
    type = string
}

variable "direct_lambda_request_template" {
  type        = string
}

variable "direct_lambda_response_template" {
  type        = string
}

variable "tags" {
    type = map(string)
}