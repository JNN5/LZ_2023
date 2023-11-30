data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "dead_letter_queue" {
  for_each                          = var.sqs_deadletter_queues
  name                              = each.key
  delay_seconds                     = each.value.delay_seconds
  max_message_size                  = each.value.max_message_size_bytes
  message_retention_seconds         = each.value.message_retention_seconds
  receive_wait_time_seconds         = each.value.receive_wait_time_seconds
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_sqs_queue" "queue" {
  for_each                  = var.sqs_queues
  name                      = each.key
  delay_seconds             = each.value.delay_seconds
  max_message_size          = each.value.max_message_size_bytes
  message_retention_seconds = each.value.message_retention_seconds
  receive_wait_time_seconds = each.value.receive_wait_time_seconds
  redrive_policy = each.value.dead_letter_name != "" ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue[each.value.dead_letter_name].arn
    maxReceiveCount     = each.value.max_receive_count
  }) : null
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_sqs_queue_policy" "deadletter_policy" {
  for_each  = aws_sqs_queue.dead_letter_queue
  queue_url = each.value.id

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__owner_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "SQS:*",
      "Resource": "${each.value.arn}"
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "policy" {
  for_each  = aws_sqs_queue.queue
  queue_url = each.value.id

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__owner_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "SQS:*",
      "Resource": "${each.value.arn}"
    }
  ]
}
POLICY
}
