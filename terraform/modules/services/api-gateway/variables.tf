variable "api_gw_endpoint_configuration_type" {
  description = "Specify the type of endpoint for API GW to be setup as. [EDGE, REGIONAL, PRIVATE]. Defaults to REGIONAL"
  default     = "REGIONAL"
}

variable "api_gw_name" {
  description = "The name of the REST API"
}

variable "api_gw_description" {
  description = "The description of the REST API"
  type        = string
}

variable "api_resources" {
  type = map(any)
}

variable "lambda_arns" {

}

variable "api_gateway_role_arn" {
  description = "The role for API GW to access Cloudwatch"
}

variable "api_gw_usage_plan_name" {
  description = "Name of usage plan"
}

variable "api_gw_keys" {
  description = "API key list"
}

variable "tags" {
  type = map(string)
}

variable "api_gw_authorizer_name" {
  description = "Name of API gateway authorizer"
}

variable "user_pool" {
  type        = string
  description = "Name of the Cognito user pool to be used for the API Gateway authorizer"
}

variable "api_cors" {
  description = "Cors of API"
}

variable "stage_name" {
  description = "Stage Name"
}

# variable "custom_auth_lambda_name" {
#   description = "Name of API gateway custom authorizer to be created"
# }

# variable "lambda_invoke_arns" {
#   description = "Invoke ARNs of Lambda (used for custom authorizer)"
# }
