variable "parameter_name" {
  type = string

  validation {
    condition     = startswith(var.parameter_name, "/")
    error_message = "parameter_name must be a fully qualified path starting with \"/\"."
  }
}

variable "parameter_value" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
