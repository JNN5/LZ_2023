data "aws_caller_identity" "current" {}
locals {
  # 2 lines below is for custom authorizer
  #auth_lambda_arn        = var.lambda_arns[var.custom_auth_lambda_name]
  #auth_lambda_invoke_arn = var.lambda_invoke_arns[var.custom_auth_lambda_name]
  new_stage_name = "PROD"
}

resource "aws_api_gateway_account" "api_gw_account" {
  cloudwatch_role_arn = var.api_gateway_role_arn
}

resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_gw_name
  description = var.api_gw_description
  endpoint_configuration {
    types = [var.api_gw_endpoint_configuration_type]
  }

  tags = merge(
    var.tags,
    {
      Name = var.api_gw_name
    },
  )
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.stage_name
  depends_on = [
    aws_api_gateway_integration.request_method_integration,
    aws_api_gateway_integration_response.response_method_integration,
    aws_api_gateway_integration.opt,
    aws_api_gateway_integration_response.opt
  ]
}

resource "aws_api_gateway_resource" "api_resource" {
  for_each    = var.api_resources
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.key
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "request_method" {
  for_each             = var.api_resources
  authorization        = each.value.authorizer_type
  # authorizer_id        = each.value.authorizer_type == "CUSTOM" ? aws_api_gateway_authorizer.custom_auth.id : null
  authorizer_id        = null
  authorization_scopes = each.value.authorizer_type == "COGNITO_USER_POOLS" ? ["aws.cognito.signin.user.admin"] : null
  http_method          = each.value.method
  resource_id          = aws_api_gateway_resource.api_resource[each.key].id
  rest_api_id          = aws_api_gateway_rest_api.api.id
  api_key_required     = each.value.api_key_enabled
}

resource "aws_api_gateway_integration" "request_method_integration" {
  for_each                = var.api_resources
  http_method             = aws_api_gateway_method.request_method[each.key].http_method
  resource_id             = aws_api_gateway_resource.api_resource[each.key].id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  type                    = each.value.type
  uri                     = "arn:aws:apigateway:ap-southeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-southeast-1:${data.aws_caller_identity.current.account_id}:function:${each.value.lambda_name}/invocations"
  integration_http_method = "POST"

  request_templates    = each.value.request_templates
  passthrough_behavior = each.value.request_templates == {} ? "WHEN_NO_MATCH" : "WHEN_NO_TEMPLATES"
}

resource "aws_api_gateway_method_response" "response_method" {
  for_each    = var.api_resources
  http_method = each.value.method
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type"                      = true,
    "method.response.header.Access-Control-Allow-Origin"       = true,
    "method.response.header.Access-Control-Allow-Methods"      = true,
    "method.response.header.Access-Control-Allow-Headers"      = true,
    "method.response.header.content-security-policy"           = true,
    "method.response.header.strict-transport-security"         = true,
    "method.response.header.x-content-type-options"            = true,
    "method.response.header.x-frame-options"                   = true,
    "method.response.header.cache-control"                     = true,
    "method.response.header.x-xss-protection"                  = true,
    "method.response.header.x-permitted-cross-domain-policies" = true
  }
  response_models = each.value.is_html_response ? {} : { "application/json" = "Empty" }

  depends_on = [aws_api_gateway_integration.request_method_integration]
}

resource "aws_api_gateway_integration_response" "response_method_integration" {
  for_each    = var.api_resources
  http_method = each.value.method
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = aws_api_gateway_method_response.response_method[each.key].status_code
  response_parameters = {
    "method.response.header.Content-Type"                      = each.value.is_html_response ? "'text/html'" : "'application/json'"
    "method.response.header.Access-Control-Allow-Origin"       = each.value.cors == "" ? var.api_cors : each.value.cors,
    "method.response.header.Access-Control-Allow-Headers"      = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'",
    "method.response.header.Access-Control-Allow-Methods"      = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.x-content-type-options"            = "'nosniff'",
    "method.response.header.x-xss-protection"                  = "'1; mode=block'",
    "method.response.header.content-security-policy"           = each.value.is_html_response ? "'default-src 'self' 'unsafe-inline''" : "'default-src 'self'; object-src 'none';'",
    "method.response.header.x-frame-options"                   = "'SAMEORIGIN'",
    "method.response.header.cache-control"                     = "'no-store'",
    "method.response.header.strict-transport-security"         = "'max-age=31536000; includeSubDomains; preload'",
    "method.response.header.x-permitted-cross-domain-policies" = "'master-only'"
  }
  response_templates = each.value.response_templates
}

resource "aws_lambda_permission" "apigw-lambda-allow" {
  for_each      = var.api_resources
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowExecutionFromApiGateway"
  depends_on    = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api_resource]
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method" "opt" {
  for_each = var.api_resources

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_resource[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "opt" {
  for_each          = var.api_resources
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.api_resource[each.key].id
  http_method       = aws_api_gateway_method.opt[each.key].http_method
  request_templates = { "application/json" = jsonencode({ statusCode = 200 }) }
  type              = "MOCK"
}

resource "aws_api_gateway_integration_response" "opt" {
  for_each    = var.api_resources
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.opt[each.key].http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"       = each.value.cors == "" ? var.api_cors : each.value.cors,
    "method.response.header.Access-Control-Allow-Headers"      = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'",
    "method.response.header.Access-Control-Allow-Methods"      = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.x-content-type-options"            = "'nosniff'",
    "method.response.header.x-xss-protection"                  = "'1; mode=block'",
    "method.response.header.content-security-policy"           = "'default-src 'self'; object-src 'none';'",
    "method.response.header.x-frame-options"                   = "'SAMEORIGIN'",
    "method.response.header.cache-control"                     = "'no-store'",
    "method.response.header.strict-transport-security"         = "'max-age=31536000; includeSubDomains; preload'",
    "method.response.header.x-permitted-cross-domain-policies" = "'master-only'"
  }
  depends_on = [aws_api_gateway_integration.opt, aws_api_gateway_method_response.opt]
}

resource "aws_api_gateway_method_response" "opt" {
  for_each    = var.api_resources
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.opt[each.key].http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"       = true,
    "method.response.header.Access-Control-Allow-Methods"      = true,
    "method.response.header.Access-Control-Allow-Headers"      = true,
    "method.response.header.content-security-policy"           = true,
    "method.response.header.strict-transport-security"         = true,
    "method.response.header.x-content-type-options"            = true,
    "method.response.header.x-frame-options"                   = true,
    "method.response.header.cache-control"                     = true,
    "method.response.header.x-xss-protection"                  = true,
    "method.response.header.x-permitted-cross-domain-policies" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [aws_api_gateway_method.opt]
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.deployment.stage_name
  method_path = "*/*"
  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

  depends_on = [aws_api_gateway_account.api_gw_account]
}


resource "aws_api_gateway_usage_plan" "usage_plan" {
  name        = var.api_gw_usage_plan_name
  description = "Usage plan for API"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_deployment.deployment.stage_name
  }
  tags = merge(
    var.tags,
    {
      Name = var.api_gw_usage_plan_name
    },
  )
}

resource "aws_api_gateway_api_key" "api_key" {
  for_each    = var.api_gw_keys
  name        = each.key
  description = each.value.description

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  for_each      = var.api_gw_keys
  key_id        = aws_api_gateway_api_key.api_key[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

# resource "null_resource" "api_deployment" {
#   triggers = {
#     uuid = uuid()
#   }
#   provisioner "local-exec" {
#     command = <<EOF
#      aws apigateway create-deployment --rest-api-id ${aws_api_gateway_rest_api.api.id} --stage-name ${aws_api_gateway_deployment.deployment.stage_name}
#    EOF
#   }
# }

##### Cognito Authorizer unhide only if required ########

# data "aws_cognito_user_pools" "user_pools" {
#   name  = "${var.user_pool}"
# }
# resource "aws_api_gateway_authorizer" "cognito_auth" {
#   name          = var.api_gw_authorizer_name
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   type          = "COGNITO_USER_POOLS"
#   provider_arns = data.aws_cognito_user_pools.user_pools.arns

#   depends_on = [
#     data.aws_cognito_user_pools.user_pools
#   ]
# }
##########################################################

##### CUSTOM Authorizer unhide only if required ##########
# resource "aws_api_gateway_authorizer" "custom_auth" {
#   name                             = "custom_auth"
#   rest_api_id                      = aws_api_gateway_rest_api.api.id
#   authorizer_uri                   = local.auth_lambda_invoke_arn
#   authorizer_credentials           = aws_iam_role.invocation_role.arn
#   identity_validation_expression   = "^[a-zA-Z0-9]{30}$"
#   authorizer_result_ttl_in_seconds = 0
# }

# resource "aws_iam_role" "invocation_role" {
#   name = "api_gateway_auth_invocation_role"
#   path = "/"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "apigateway.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy" "invocation_policy" {
#   name = "api_gateway_auth_invocation_policy"
#   role = aws_iam_role.invocation_role.id

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "lambda:InvokeFunction",
#       "Effect": "Allow",
#       "Resource": "${local.auth_lambda_arn}"
#     }
#   ]
# }
# EOF
# }
##########################################################

resource "aws_api_gateway_gateway_response" "cors_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = var.api_cors
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'"
  }
}

resource "aws_api_gateway_gateway_response" "cors_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = var.api_cors
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'"
  }
}
