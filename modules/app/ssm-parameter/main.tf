resource "aws_ssm_parameter" "this" {
  name  = var.parameter_name
  type  = "String"
  value = var.parameter_value
  tags  = var.tags
}
