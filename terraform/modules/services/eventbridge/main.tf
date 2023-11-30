data "aws_caller_identity" "current" {}

data "aws_lambda_function" "target_function" {
  for_each = { for name, schedule in var.eventbridge_schedules : schedule.target_name => schedule if schedule.target_type == "lambda" }

  function_name = each.value.target_name
}

data "aws_sqs_queue" "target_queue" {
  for_each = { for name, schedule in var.eventbridge_schedules : schedule.target_name => schedule if schedule.target_type == "sqs" }

  name = each.value.target_name
}

resource "aws_scheduler_schedule" "schedule" {
  for_each   = var.eventbridge_schedules
  name       = each.key
  description = each.value.description

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = each.value.schedule_expression

  target {
    arn      = each.value.target_type == "lambda" ? data.aws_lambda_function.target_function[each.value.target_name].arn : data.aws_sqs_queue.target_queue[each.value.target_name].arn
    role_arn = var.eventbridge_scheduler_role_arn
  }

  depends_on = [
    data.aws_lambda_function.target_function,
    data.aws_sqs_queue.target_queue
  ]
}

resource "aws_lambda_permission" "lambda_permission" {
  for_each = var.eventbridge_schedules
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = each.value.target_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.schedule[each.key].arn

  depends_on = [
    data.aws_lambda_function.target_function,
    aws_scheduler_schedule.schedule
  ]
}
