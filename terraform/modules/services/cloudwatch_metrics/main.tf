locals {
  log_group_list = flatten([
    for metric_key, metric in var.cloudwatch_metrics : [
      for log_group_name in metric.log_group_name : {
        metric_key     = metric_key
        log_group_name = "/aws/lambda/${log_group_name}"
        metric         = metric
        metric         = metric

      }
    ]
  ])

  subscriber_list = flatten([
    for metric_key, metric in var.cloudwatch_metrics : [
      for subscriber in metric.email_subscriber : {
        metric_key = metric_key
        subscriber = subscriber
      }
    ]
  ])
  
  dashboard_lambda_invocation_metric = [
      for lambda in var.cloudwatch_dashboard_lambdas : 
      [ "AWS/Lambda", "Invocations", "FunctionName", lambda]
  ]
  
  dashboard_lambda_error_metric = [
      for lambda in var.cloudwatch_dashboard_lambdas : 
      [ "AWS/Lambda", "Errors", "FunctionName", lambda]
  ]
  
  dashboard_lambda_duration_metric = [
      for lambda in var.cloudwatch_dashboard_lambdas : 
      [ "AWS/Lambda", "Duration", "FunctionName", lambda]
  ]
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each = {
    for item in local.log_group_list : "${item.metric_key}-${item.log_group_name}" => item
  }
  name              = each.value.log_group_name
  retention_in_days = 90

  tags = merge(
    var.tags,
    {
      Name = each.value.log_group_name
    },
  )
}

resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  for_each = {
    for item in local.log_group_list : "${item.metric_key}-${item.log_group_name}" => item
  }
  name           = each.key
  log_group_name = each.value.log_group_name
  pattern        = each.value.metric.pattern
  metric_transformation {
    name      = each.key
    namespace = var.tags.Project
    value     = each.value.metric.metric_value
  }

  depends_on = [aws_cloudwatch_log_group.log_group]
}

//set up the alarm
resource "aws_cloudwatch_metric_alarm" "metric_alarm" {
  for_each = {
    for item in local.log_group_list : "${item.metric_key}-${item.log_group_name}" => item
  }
  alarm_name          = each.key
  metric_name         = aws_cloudwatch_log_metric_filter.metric_filter[each.key].name
  threshold           = each.value.metric.threshold
  statistic           = each.value.metric.statistic
  comparison_operator = each.value.metric.comparison_operator
  datapoints_to_alarm = each.value.metric.datapoints_to_alarm
  evaluation_periods  = each.value.metric.evaluation_periods
  period              = each.value.metric.period
  namespace           = var.tags.Project
  alarm_description   = each.value.metric.alarm_description

  alarm_actions = [aws_sns_topic.topic[each.value.metric_key].arn]
}

//set up the sns
resource "aws_sns_topic" "topic" {
  for_each = var.cloudwatch_metrics
  name     = each.key

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_sns_topic_subscription" "topic_sub" {
  for_each = {
    for item in local.subscriber_list : "${item.metric_key}-${item.subscriber}" => item
  }

  topic_arn = aws_sns_topic.topic[each.value.metric_key].arn
  protocol  = "email"
  endpoint  = each.value.subscriber
}

/* Cloudwatch Dashboard */

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.cloudwatch_dashboard_name
  
  dashboard_body = jsonencode(
  {
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": local.dashboard_lambda_invocation_metric,
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-1",
                "stat": "Sum",
                "period": 3600,
                "title": "Lambda Invocations per hour"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": local.dashboard_lambda_error_metric,
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-1",
                "stat": "Sum",
                "period": 86400,
                "title": "Lambda Errors per day"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": local.dashboard_lambda_duration_metric,
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-1",
                "stat": "Average",
                "period": 3600,
                "title": "Lambda duration on average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApiGateway", "5XXError", "ApiName", "${var.cloudwatch_dashboard_apigw}" ],
                    [ ".", "4XXError", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-1",
                "stat": "Sum",
                "period": 86400,
                "title": "API Errors per day"
            }
        }
    ]
  })
  
}