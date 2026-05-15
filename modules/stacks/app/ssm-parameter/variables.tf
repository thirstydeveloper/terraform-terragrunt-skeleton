variable "parameter_name" {
  type = string
}

variable "parameter_value" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
