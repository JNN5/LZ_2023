output "dynamodb_table_names" {
  value = keys(aws_dynamodb_table.table)
}

output "dynamodb_table_hash_keys" {
  value = values(aws_dynamodb_table.table).*.hash_key
}

output "dynamodb_table_range_keys" {
  value = values(aws_dynamodb_table.table).*.range_key
}

output "dynamodb_table_arns" {
  value = values(aws_dynamodb_table.table).*.arn
}

output "dynamodb_table_stream_arns" {
  value = values(aws_dynamodb_table.table).*.stream_arn
}
