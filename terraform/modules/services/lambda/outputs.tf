output "lambda_name" {
  value = keys(aws_lambda_function.lambda)
}

output "lambda_arns" {
  value = {
    for name, lambda in aws_lambda_function.lambda :
    lambda.function_name => lambda.arn
  }
}

output "lambda_last_modified" {
  value = values(aws_lambda_function.lambda).*.last_modified
}

output "lambda_invoke_arns" {
  value = {
    for name, lambda in aws_lambda_function.lambda :
    lambda.function_name => lambda.invoke_arn
  }
}
