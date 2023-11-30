################# Global #################
variable "region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-1"
}

############### COGNITO ################
variable "cognito_user_pools" {
  type = map(any)
  description = "List of cognito user pools to be created"
}

variable "cognito_user_pool_clients" {
  type = map(any)
  description = "List of cognito user pool clients"
}

variable "cognito_user_pool_passkeys" {
  type = any
}

variable "user_pool_clients_passkeys" {
  type = map(any)
}

################ DynamoDB ################
variable "dynamodb_tables" {
  type        = list(any)
  description = "List of map of dynamoDB to be created"
}

################## IAM ##################
variable "lambda_role_name" {
  type        = string
  description = "lambda role to be created"
}

variable "appsync_service_role_name" {
  type        = string
  description = "Name of role that Appsync should assume when accessing datasources"
}

variable "subscription_table_name" {
  type        = string
  description = "Name of webpush subscription table"
}

variable "appsync_cloudwatch_role_name" {
  type        = string
  description = "Name of role that Appsync should assume when writing to Cloudwatch"
}

################ LAMBDA ################
variable "lambdas" {
  type = map(any)
}

variable "lambda_layers" {
  type = map(any)
}

variable "lambda_permissions" {
  type = list(any)
}

variable "lambda_event_source_mapping" {
  type = map(any)
}

variable "lambda_subnet_ids" {
  type = list(any)
}

variable "lambda_security_group_ids" {
  type = list(any)
}

############# AppConfig ##############
variable "feature_flags" {
  type = map(object({
    name    = string
    enabled = bool,
    })
  )
}


############# API-Gateway ###############
variable "api_gw_name" {
  type        = string
  description = "The name of the REST API"
}

variable "api_gw_description" {
  type        = string
  description = "The description of the REST API"
}
variable "api_cors" {
  type        = string
  description = "API CORS URL for OPTIONS method"
}

variable "api_gw_authorizer_name" {
  type        = string
  description = "If there is cognito being used to authenticate the API"
  default     = ""
}

variable "user_pool" {
  type        = string
  description = "Name of the Cognito user pool to be used for the API Gateway authorizer"
}

variable "api_gateway_role_name" {
  type        = string
  description = "Role to access cloudwatch to input log"
}

variable "api_gw_usage_plan_name" {
  type        = string
  description = "Usage plan name"
}

variable "api_gw_keys" {
  type        = map(any)
  description = "API Keys map"
}

variable "api_resources" {
  type        = map(any)
  description = "Map of API resources to be created"
}

variable "stage_name" {
  description = "Stage Name"
}

# variable "custom_auth_lambda_name" {
#   type        = string
#   description = "Name of API gateway custom authorizer to be created"
# }

############## APPSYNC ####################
variable "appsync" {
  type        = any
  description = "Object containing necessary vars to create appsync module"
}

variable "appsync_datasources" {
  type        = map(any)
  description = "List of appsync datasources"
}

variable "appsync_functions" {
  type        = map(any)
  description = "List of appsync functions"
}

variable "appsync_resolvers" {
  type        = any
  description = "List of appsync resolvers"
}

variable "direct_lambda_request_template" {
  type        = string
  description = "Request template for direct lambda"
}

variable "direct_lambda_response_template" {
  type        = string
  description = "Response template for direct lambda"
}

################## S3 ####################
variable "s3_buckets" {
  type = map(object({
    name    = string,
    acl     = string,
    kms_key = string,

    # For S3 event notifications
    should_trigger_lambda = bool
    lambda_name           = string
    events                = list(string)
    filter_prefix         = string
    filter_suffix         = string
  }))
}

################## KMS ####################
variable "kms_keys" {
  type = map(any)
}

variable "kms_role" {
  type = string
}

################## EVENTBRIDGE ####################
variable "eventbridge_schedules" {
  type = map(object({
    schedule_expression = string
    target_type         = string
    target_name         = string
    description         = string
  }))
}

variable "eventbridge_scheduler_role" {
  type = string
}

################## SNS ####################
variable "sns_list" {
  type = map(any)
}

################## SQS ####################
variable "sqs_queues" {
  type = map(any)
}

variable "sqs_deadletter_queues" {
  type = map(any)
}

################## SSM ####################
variable "ssm_list" {
  type = map(any)
}

################# Tags ###################
variable "tags" {
  type = map(string)
}
