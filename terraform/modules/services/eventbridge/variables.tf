variable "eventbridge_schedules" {
  type = map(object({
    schedule_expression = string
    target_type         = string
    target_name         = string
    description         = string
  }))
}

variable "eventbridge_scheduler_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
}