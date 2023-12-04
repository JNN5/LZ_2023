provider "aws" {
  region = var.region
}

# terraform {
#   backend "s3" {}
# }

# module "cognito" {
#   source             = "./modules/services/cognito"
#   cognito_user_pools = var.cognito_user_pools
#   user_pool_clients  = var.cognito_user_pool_clients
#   tags               = var.tags
# }
# module "cognito_passkeys" {
#   source                     = "./modules/services/cognito_passkeys"
#   cognito_user_pool_passkeys = var.cognito_user_pool_passkeys
#   user_pool_clients_passkeys = var.user_pool_clients_passkeys
#   lambda_role_arn            = module.iam.lambda_role_arn
#   tags                       = var.tags

#   depends_on = [
#     module.iam
#   ]
# }

module "dynamodb" {
  source          = "./modules/services/dynamodb"
  dynamodb_tables = var.dynamodb_tables
  # kms_keys        = module.kms.key_arn
  tags            = var.tags
}

module "iam" {
  source                       = "./modules/services/iam"
  lambda_role_name             = var.lambda_role_name
  api_gateway_role_name        = var.api_gateway_role_name
  # appsync_service_role_name    = var.appsync_service_role_name
  # appsync_cloudwatch_role_name = var.appsync_cloudwatch_role_name
  # subscription_table_name      = var.subscription_table_name
  dynamodb_table_arns          = module.dynamodb.dynamodb_table_arns
  eventbridge_scheduler_role   = var.eventbridge_scheduler_role
}

module "lambda" {
  source                      = "./modules/services/lambda"
  lambdas                     = var.lambdas
  lambda_subnet_ids           = var.lambda_subnet_ids
  lambda_security_group_ids   = var.lambda_security_group_ids
  lambda_role_arn             = module.iam.lambda_role_arn
  lambda_layers               = var.lambda_layers
  lambda_permissions          = var.lambda_permissions
  lambda_event_source_mapping = var.lambda_event_source_mapping
  # kms_keys                    = module.kms.key_id
  # user_pool_arns              = module.cognito.pool_arns
  # appsync_url                 = module.appsync.appsync_url
  sqs_arns                    = module.sqs.sqs_arns
  tags                        = var.tags
}

# module "appconfig" {
#   source        = "./modules/services/appconfig"
#   feature_flags = var.feature_flags
#   tags          = var.tags
# }

module "api-gateway" {
  source                 = "./modules/services/api-gateway"
  api_resources          = var.api_resources
  api_gw_name            = var.api_gw_name
  api_gw_description     = var.api_gw_description
  stage_name             = var.stage_name
  lambda_arns            = module.lambda.lambda_arns
  api_gateway_role_arn   = module.iam.api_gateway_role_arn
  api_gw_usage_plan_name = var.api_gw_usage_plan_name
  api_gw_keys            = var.api_gw_keys
  api_gw_authorizer_name = var.api_gw_authorizer_name
  api_cors               = var.api_cors
  # user_pool              = var.user_pool
  # Only enable the below for custom authorizers
  # custom_auth_lambda_name  = var.custom_auth_lambda_name
  # lambda_invoke_arns       = module.lambda.lambda_invoke_arns
  tags = var.tags
}

# module "appsync" {
#   source                          = "./modules/services/appsync"
#   appsync                         = var.appsync
#   appsync_datasources             = var.appsync_datasources
#   appsync_functions               = var.appsync_functions
#   appsync_service_role_arn        = module.iam.appsync_service_role_arn
#   appsync_resolvers               = var.appsync_resolvers
#   appsync_cloudwatch_role_arn     = module.iam.appsync_cloudwatch_role_arn
#   lambda_arns                     = module.lambda.lambda_arns
#   user_pool_ids                   = module.cognito.pool_ids
#   direct_lambda_request_template  = var.direct_lambda_request_template
#   direct_lambda_response_template = var.direct_lambda_response_template
#   tags                            = var.tags
# }

# module "kms" {
#   source   = "./modules/services/kms"
#   kms_keys = var.kms_keys
#   kms_role = var.kms_role
#   tags     = var.tags
# }

module "eventbridge" {
  source                         = "./modules/services/eventbridge"
  eventbridge_schedules          = var.eventbridge_schedules
  eventbridge_scheduler_role_arn = module.iam.eventbridge_scheduler_role_arn
  tags                           = var.tags

  depends_on = [
    module.lambda
  ]
}

module "sns" {
  source   = "./modules/services/sns"
  sns_list = var.sns_list
  tags     = var.tags
}

module "s3" {
  source      = "./modules/services/s3"
  s3_buckets  = var.s3_buckets
  lambda_arns = module.lambda.lambda_arns
  # kms_keys    = module.kms.key_arn
  tags        = var.tags
}

module "sqs" {
  source                = "./modules/services/sqs"
  sqs_queues            = var.sqs_queues
  sqs_deadletter_queues = var.sqs_deadletter_queues
  tags                  = var.tags
}

module "ssm" {
  source   = "./modules/services/ssm"
  ssm_list = var.ssm_list
  tags     = var.tags
}
