locals {
    subscriber_list = flatten([
        for sns_key, sns in var.sns_list : [
            for subscriber in sns.subscriber : {
                sns_key = sns_key
                subscriber = subscriber
            }
        ]
    ])
}

resource "aws_sns_topic" "topic" {
  for_each    = var.sns_list
  name         = each.key
  
  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )
}

resource "aws_sns_topic_subscription" "topic_sub" {
  for_each = {
    for item in local.subscriber_list : "${item.sns_key}-${item.subscriber}" => item
  }
  topic_arn    = aws_sns_topic.topic[each.value.sns_key].arn
  protocol     = "email"
  endpoint     = each.value.subscriber
}