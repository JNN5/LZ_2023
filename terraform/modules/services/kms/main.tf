data "aws_caller_identity" "current" {}

data "aws_iam_role" "kms_role" {
  name = var.kms_role
}
resource "aws_kms_key" "key" {
  for_each    = var.kms_keys
  description = each.value.description

  tags = merge(
    var.tags,
    {
      Name = each.key
    },
  )

  policy = <<EOT
{
    "Id": "key-consolepolicy-3",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_iam_role.kms_role.arn}"
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        }
    ]
}
EOT



}

resource "aws_kms_alias" "alias" {
  for_each      = var.kms_keys
  name          = "alias/${each.key}"
  target_key_id = aws_kms_key.key[each.key].key_id
}
