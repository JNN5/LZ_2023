variable "cloudwatch_metrics" {
  type = map(any)
}

variable "tags" {
  type = map(string)
}

variable "cloudwatch_dashboard_lambdas" {
  type = list(string)
}

variable "cloudwatch_dashboard_name" {
  type = string
}

variable "cloudwatch_dashboard_apigw" {
  type = string
}