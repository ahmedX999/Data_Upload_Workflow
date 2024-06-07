provider "aws" {
  region = "us-east-1" # Specify your region here
}



locals {
  lambda_function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
}

# Data source to check if the Lambda function exists
data "aws_lambda_function" "existing_lambda" {
  function_name = local.lambda_function_name

  # Using a count to conditionally fetch the data or not
  count = length(try([aws_lambda_function.existing_lambda.arn], [])) == 1 ? 1 : 0
}

# Conditional resource creation based on whether the function exists
resource "aws_lambda_function" "new_lambda" {
  count = length(try([data.aws_lambda_function.existing_lambda.arn], [])) == 0 ? 1 : 0

  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest" : "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

output "lambda_function_status" {
  value = length(try([data.aws_lambda_function.existing_lambda.arn], [])) == 1 ? "Lambda function exists" : "Lambda function created"
}

# A null resource to display a message based on the existence of the Lambda function
resource "null_resource" "lambda_status" {
  count = length(try([data.aws_lambda_function.existing_lambda.arn], [])) == 1 ? 1 : 0

  provisioner "local-exec" {
    command = "echo Lambda function exists"
  }
}

resource "null_resource" "lambda_creation" {
  count = length(try([data.aws_lambda_function.existing_lambda.arn], [])) == 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo Lambda function created"
  }
}
