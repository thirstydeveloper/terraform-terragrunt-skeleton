# Uses a mocked AWS provider: no credentials or API calls required.

mock_provider "aws" {
  mock_resource "aws_ssm_parameter" {
    defaults = {
      arn = "arn:aws:ssm:us-east-1:123456789012:parameter/test/example"
    }
  }
}

variables {
  parameter_name  = "/test/example"
  parameter_value = "hello"
}

run "creates_string_parameter" {
  command = apply

  variables {
    tags = {
      environment = "test"
    }
  }

  assert {
    condition     = aws_ssm_parameter.this.type == "String"
    error_message = "Parameter type should be String"
  }

  assert {
    condition     = aws_ssm_parameter.this.name == var.parameter_name
    error_message = "Parameter name not passed through"
  }

  assert {
    condition     = aws_ssm_parameter.this.value == var.parameter_value
    error_message = "Parameter value not passed through"
  }

  assert {
    condition     = aws_ssm_parameter.this.tags == tomap({ environment = "test" })
    error_message = "Tags not passed through"
  }

  assert {
    condition     = output.name == var.parameter_name
    error_message = "name output should match parameter_name"
  }

  assert {
    condition     = output.arn == "arn:aws:ssm:us-east-1:123456789012:parameter/test/example"
    error_message = "arn output should come from the resource"
  }
}

run "tags_default_empty" {
  command = apply

  assert {
    condition     = length(aws_ssm_parameter.this.tags) == 0
    error_message = "Tags should default to empty"
  }
}

run "rejects_name_without_leading_slash" {
  command = plan

  variables {
    parameter_name = "no-leading-slash"
  }

  expect_failures = [var.parameter_name]
}
