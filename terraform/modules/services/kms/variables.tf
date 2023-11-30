variable "kms_keys" {
  type = map
}

variable "kms_role" {
  type = string
}

variable "tags" {
  type    = map(string)
}