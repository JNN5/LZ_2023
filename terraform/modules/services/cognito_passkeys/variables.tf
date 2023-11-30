variable "cognito_user_pool_passkeys" {
  type = object({
    name                 = string
    invite_email_subject = string
    invite_email_message = string
    domain               = string
  })
}

variable "user_pool_clients_passkeys" {
  type = map(object({
    callback_urls  = list(string)
    logout_urls    = list(string)
  }))
}

variable "lambda_role_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}