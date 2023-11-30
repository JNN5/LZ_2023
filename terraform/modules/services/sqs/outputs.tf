output "sqs_arns" {
  description = "Map of sqs names to ARNs"
  value = tomap({
    for k, sqs in aws_sqs_queue.queue : k => sqs.arn
  })
}
