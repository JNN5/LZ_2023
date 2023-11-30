variable "feature_flags" {
    type = map(object({
        name    = string
        enabled = bool,
    })
  )
}

variable "tags" {
  type    = map(string)
}
