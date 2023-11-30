variable "cognito_user_pools" {
  type = map(object({
    disable_self_signup      = bool
    invite_email_subject     = string
    invite_email_message     = string
    pw_min_length            = number
    pw_require_numbers       = bool
    pw_require_symbols       = bool
    pw_require_uppercase     = bool
    pw_temp_validity_days    = number
    recovery_mechanism       = string
    custom_string_attributes = list(map(any))
    custom_number_attributes = list(map(any))
    domain                   = string
  }))
}

variable "user_pool_clients" {
  type = map(object({
    user_pool_name               = string
    generate_secret              = bool
    access_token_validity_hours  = number
    id_token_validity_hours      = number
    refresh_token_validity_days  = number
    explicit_auth_flows          = list(string)
    allowed_oauth_flows          = list(string)
    allowed_oauth_scopes         = list(string)
    supported_identity_providers = list(string)
    callback_urls                = list(string)
    logout_urls                  = list(string)
    image                        = string
    css                          = string
  }))
}

variable "tags" {
  type = map(string)
}
