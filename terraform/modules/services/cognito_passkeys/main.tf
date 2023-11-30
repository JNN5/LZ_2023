
data "aws_caller_identity" "current" {}

locals {
  lambdas = {
    create_auth_challenge = "modules/services/cognito_passkeys/lambda/create_auth_challenge.zip"
    define_auth_challenge = "modules/services/cognito_passkeys/lambda/define_auth_challenge.zip"
    verify_auth_challenge_response = "modules/services/cognito_passkeys/lambda/verify_auth_challenge_response.zip"
  }
}
resource "aws_cognito_user_pool" "passkeys_pool" {
  name = var.cognito_user_pool_passkeys.name

  lambda_config {
    create_auth_challenge = aws_lambda_function.lambda["create_auth_challenge"].arn
    define_auth_challenge = aws_lambda_function.lambda["define_auth_challenge"].arn
    verify_auth_challenge_response = aws_lambda_function.lambda["verify_auth_challenge_response"].arn
  }

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
    invite_message_template {
      email_subject = var.cognito_user_pool_passkeys.invite_email_subject
      email_message = var.cognito_user_pool_passkeys.invite_email_message
      sms_message   = "Placeholder message {username}{####}" # Terraform throws an error if sms_message is not defined, even if it's unused
    }
  }

  password_policy {
    minimum_length                   = 12
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 30
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  schema {
    name = "public_key_cred"
    attribute_data_type = "String"
    mutable = true
    string_attribute_constraints {
      max_length = 2048
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_domain" "cognito-domain" {
  domain       = var.cognito_user_pool_passkeys.domain
  user_pool_id = aws_cognito_user_pool.passkeys_pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  for_each                             = var.user_pool_clients_passkeys
  name                                 = each.key
  user_pool_id                         = aws_cognito_user_pool.passkeys_pool.id
  generate_secret                      = false
  access_token_validity                = 24
  id_token_validity                    = 24
  refresh_token_validity               = 30
  prevent_user_existence_errors        = "ENABLED"
  explicit_auth_flows                  = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  write_attributes = [ "name", "custom:public_key_cred" ]
  read_attributes = [ "name" ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lambda_function" "lambda" {
  for_each         = local.lambdas
  function_name    = each.key
  filename         = each.value
  runtime          = "nodejs16.x"
  handler          = "${each.key}.handler"
  role             = var.lambda_role_arn

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_lambda_permission" "lambda_permission" {
  for_each      = local.lambdas
  statement_id  = "CognitoLambdaInvokeAccess"
  action        = "lambda:InvokeFunction"
  function_name = each.key
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.passkeys_pool.arn
  depends_on    = [aws_lambda_function.lambda, aws_cognito_user_pool.passkeys_pool]
}
