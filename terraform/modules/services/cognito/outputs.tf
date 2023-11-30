output "pool_ids" {
  description = "Map of user pool names to ids"
  value = tomap({
    for k, pool in aws_cognito_user_pool.pool : k => pool.id
  })
}

output "pool_arns" {
  description = "Map of user pool names to ARNs"
  value = tomap({
    for k, pool in aws_cognito_user_pool.pool : k => pool.arn
  })
}
