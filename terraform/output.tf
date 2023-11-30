

output "api_gw_api_url" {
  value = module.api-gateway.api_url
}

output "lambda_arns" {
  value = module.lambda.lambda_arns
}