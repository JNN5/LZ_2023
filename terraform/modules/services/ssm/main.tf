resource "aws_ssm_parameter" "parameter" {
  for_each = var.ssm_list
  name     = each.key
  type     = each.value.type
  value    = each.value.value

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )

}
