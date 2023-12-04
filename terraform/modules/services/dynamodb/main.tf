resource "aws_dynamodb_table" "table" {
  for_each         = { for ddb in var.dynamodb_tables : "${ddb.name}" => ddb }
  name             = each.key
  hash_key         = each.value.hash_key
  range_key        = lookup(each.value, "range_key", "")
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = lookup(each.value, "stream_enabled", false)
  stream_view_type = lookup(each.value, "stream_enabled", false) ? "NEW_AND_OLD_IMAGES" : null
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = lookup(each.value, "index", [])
    content {
      name               = global_secondary_index.value.index_name
      hash_key           = global_secondary_index.value.index_hash_key
      range_key          = lookup(global_secondary_index.value, "index_range_key", "")
      projection_type    = lookup(global_secondary_index.value, "index_projection_type", "INCLUDE")
      non_key_attributes = lookup(global_secondary_index.value, "index_non_key_attributes", [])
    }
  }

  # dynamic "server_side_encryption" {
  #   for_each = each.value.kms_key != "" ? [1] : []
  #   content {
  #     enabled     = true
  #     kms_key_arn = var.kms_keys[each.value.kms_key]
  #   }
  # }

  dynamic "ttl" {
    for_each = each.value.ttl_enabled ? [1] : []
    content {
      attribute_name = "ttl"
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = each.value.pit_recovery_enabled
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name           = each.key,
      Daily_Backup   = "False",
      Weekly_Backup  = "False",
      Monthly_Backup = "False"
    },
  )
}
