
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF

}
resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "lambda_role_policy"
  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "lambda_policy" {
  policy_id = "__policy_ID_lambda_role"

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sqs:*",
      "ssm:*",
      "cognito-idp:*",
      "kms:*",
      "ses:*",
      "s3:*",
      "lambda:InvokeFunction*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "dynamodb:*",
      "appsync:GraphQL",
      "appconfig:GetLatestConfiguration",
      "appconfig:StartConfigurationSession"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy" "aws_xray_write_only_access" {
  name = "AWSXRayDaemonWriteAccess"
}
resource "aws_iam_role_policy_attachment" "aws_xray_write_only_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.aws_xray_write_only_access.arn
}

resource "aws_iam_role_policy" "api_gateway_role_policy" {
  name = "api_gateway_role_policy"
  role = aws_iam_role.api_gateway_role.id

  policy = data.aws_iam_policy_document.api_gateway_policy.json
}

data "aws_iam_policy_document" "api_gateway_policy" {
  policy_id = "__policy_ID_api_gateway_role"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "api_gateway_role" {
  name = var.api_gateway_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# resource "aws_iam_role_policy" "appsync_cloudwatch_role_policy" {
#   name = "appsync_cloudwatch_role_policy"
#   role = aws_iam_role.appsync_cloudwatch_role.id

#   policy = data.aws_iam_policy_document.appsync_cloudwatch_policy.json
# }

# data "aws_iam_policy_document" "appsync_cloudwatch_policy" {
#   policy_id = "__policy_ID_appsync_role"

#   statement {
#     sid    = ""
#     effect = "Allow"
#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_role" "appsync_cloudwatch_role" {
#   name = var.appsync_cloudwatch_role_name

#   assume_role_policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#         "Effect": "Allow",
#         "Principal": {
#             "Service": "appsync.amazonaws.com"
#         },
#         "Action": "sts:AssumeRole"
#         }
#     ]
# }
# POLICY
# }

# resource "aws_iam_role" "appsync_service_role" {
#   name = var.appsync_service_role_name

#   assume_role_policy = data.aws_iam_policy_document.appsync_service_assume_role_policy.json
# }

# data "aws_iam_policy_document" "appsync_service_assume_role_policy" {
#   statement {
#     sid = "1"
#     actions = [
#       "sts:AssumeRole",
#     ]
#     principals {
#       type        = "Service"
#       identifiers = ["appsync.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role_policy" "appsync_service_role_policy" {
#   name = "appsync_service_role_policy"
#   role = aws_iam_role.appsync_service_role.id

#   policy = data.aws_iam_policy_document.appsync_service_role_policy.json
# }

# data "aws_iam_policy_document" "appsync_service_role_policy" {
#   policy_id = "__policy_ID_appsync_role"

#   statement {
#     sid    = ""
#     effect = "Allow"
#     actions = [
#       "lambda:InvokeFunction*"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = ""
#     effect = "Allow"
#     actions = [
#       "dynamodb:*"
#     ]
#     resources = ["*"]
#   }
# }

### EVENTBRIDGE ###
resource "aws_iam_role" "eventbridge_scheduler_role" {
  name = var.eventbridge_scheduler_role

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "scheduler.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy" "eventbridge_scheduler_role_policy" {
  name = "eventbridge_scheduler_role_policy"
  role = aws_iam_role.eventbridge_scheduler_role.id

  policy = data.aws_iam_policy_document.eventbridge_scheduler_policy.json
}

data "aws_iam_policy_document" "eventbridge_scheduler_policy" {
  policy_id = "__policy_ID_eventbridge_scheduler_role"

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "sqs:SendMessage"
    ]
    resources = ["*"]
  }
}