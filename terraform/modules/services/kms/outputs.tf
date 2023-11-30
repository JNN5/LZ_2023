output "key_arn" {
  description = "The arn of the key"
  value = tomap({
    for k, item in aws_kms_key.key : k => item.arn
  })
  #value       = [aws_kms_key.key.*.arn]
}

output "key_id" {
  description = "The globally unique identifier for the key"
  value = tomap({
    for k, item in aws_kms_key.key : k => item.id
  })
}