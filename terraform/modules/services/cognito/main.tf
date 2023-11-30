resource "aws_cognito_user_pool" "pool" {
  for_each = var.cognito_user_pools

  name = each.key
  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = each.value.disable_self_signup
    invite_message_template {
      email_subject = each.value.invite_email_subject
      email_message = each.value.invite_email_message
      sms_message   = "Placeholder message {username}{####}" # Terraform throws an error if sms_message is not defined, even if it's unused
    }
  }

  password_policy {
    minimum_length                   = each.value.pw_min_length
    require_numbers                  = each.value.pw_require_numbers
    require_symbols                  = each.value.pw_require_symbols
    require_uppercase                = each.value.pw_require_uppercase
    temporary_password_validity_days = each.value.pw_temp_validity_days
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = each.value.recovery_mechanism
      priority = 1
    }
  }

  dynamic "schema" {
    for_each = each.value.custom_string_attributes
    content {
      name                = schema.value["name"]
      attribute_data_type = "String"
      mutable             = true
      string_attribute_constraints {
        min_length = schema.value["min_length"]
        max_length = schema.value["max_length"]
      }
    }
  }

  dynamic "schema" {
    for_each = each.value.custom_number_attributes
    content {
      name                = schema.value["name"]
      attribute_data_type = "Number"
      mutable             = true
      number_attribute_constraints {
        min_value = schema.value["min_value"]
        max_value = schema.value["max_value"]
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_domain" "cognito-domain" {
  for_each = var.cognito_user_pools

  domain       = each.value.domain
  user_pool_id = aws_cognito_user_pool.pool[each.key].id
}

resource "aws_cognito_user_pool_client" "client" {
  for_each = var.user_pool_clients

  name                                 = each.key
  user_pool_id                         = aws_cognito_user_pool.pool[each.value.user_pool_name].id
  generate_secret                      = each.value.generate_secret
  access_token_validity                = each.value.access_token_validity_hours
  id_token_validity                    = each.value.id_token_validity_hours
  refresh_token_validity               = each.value.refresh_token_validity_days
  prevent_user_existence_errors        = "ENABLED"
  explicit_auth_flows                  = each.value.explicit_auth_flows
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  supported_identity_providers         = each.value.supported_identity_providers
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool_ui_customization" "ui_customization" {
  for_each = var.user_pool_clients

  client_id = aws_cognito_user_pool_client.client[each.key].id

  css        = file(each.value.css)
  image_file = filebase64(each.value.image)

  user_pool_id = aws_cognito_user_pool_domain.cognito-domain[each.value.user_pool_name].user_pool_id

  depends_on = [aws_cognito_user_pool.pool, aws_cognito_user_pool_client.client, aws_cognito_user_pool_domain.cognito-domain]
}
