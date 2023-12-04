data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "lambda" {
  for_each         = var.lambdas
  function_name    = each.key
  filename         = each.value.lambda_file_name
  description      = each.value.lambda_description
  runtime          = each.value.lambda_runtime
  handler          = each.value.lambda_handler
  role             = var.lambda_role_arn
  timeout          = each.value.lambda_timeout
  source_code_hash = filebase64sha256(each.value.lambda_file_name)
  memory_size      = each.value.lambda_memory_size

  layers     = concat([for l in each.value.layers : (length(regexall("arn:aws", l)) > 0 ? l : aws_lambda_layer_version.lambda_layer[l].arn)], ["arn:aws:lambda:ap-southeast-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:17"])
  depends_on = [aws_lambda_layer_version.lambda_layer]

  tracing_config {
    mode = "Active"
  }
  dynamic "environment" {
    for_each = each.value.environment_variables
    content {
      variables = each.value.kms_key == "" ? environment.value : merge(
        environment.value,
        {
          # KEY_ID      = var.kms_keys[each.value.kms_key]
          # APPSYNC_URL = var.appsync_url
        }
      )
    }
  }

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_lambda_layer_version" "lambda_layer" {
  for_each            = var.lambda_layers
  layer_name          = each.key
  filename            = each.value.file_name
  description         = each.value.description
  source_code_hash    = filebase64sha256(each.value.file_name)
  compatible_runtimes = each.value.compatible_runtimes
}

# resource "aws_lambda_permission" "lambda_permission" {
#   for_each      = { for lambda_perm in var.lambda_permissions : join("-", [lambda_perm.function_name, lambda_perm.statement_id]) => lambda_perm }
#   statement_id  = each.value.statement_id
#   action        = each.value.action
#   function_name = each.value.function_name
#   principal     = each.value.principal
#   source_arn    = var.user_pool_arns[each.value.source_name]
#   depends_on    = [aws_lambda_function.lambda]
# }

resource "aws_lambda_event_source_mapping" "trigger" {
  for_each                = var.lambda_event_source_mapping
  event_source_arn        = var.sqs_arns[each.value.source_name]
  function_name           = each.key
  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [aws_lambda_function.lambda]
}
