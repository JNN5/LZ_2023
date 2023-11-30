output "pool_id" {
  description = "Map of user pool names to ids"
  value = aws_cognito_user_pool.passkeys_pool.id
}

output "pool_arn" {
  description = "Map of user pool names to ARNs"
  value = aws_cognito_user_pool.passkeys_pool.arn
}
