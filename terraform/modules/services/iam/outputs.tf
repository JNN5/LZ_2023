output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "api_gateway_role_arn" {
  value = aws_iam_role.api_gateway_role.arn
}

output "appsync_service_role_arn" {
  value = aws_iam_role.appsync_service_role.arn
}

output "appsync_cloudwatch_role_arn" {
  value = aws_iam_role.appsync_cloudwatch_role.arn
}

output "eventbridge_scheduler_role_arn" {
  value = aws_iam_role.eventbridge_scheduler_role.arn
}
