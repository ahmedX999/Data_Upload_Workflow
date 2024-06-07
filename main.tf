provider "aws" {
  region = "us-east-1" # Specify your region here
}


locals {
  lambda_function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
}

# Data source to check if the Lambda function exists
data "aws_lambda_function" "existing_lambda" {
  count = 1
  function_name = local.lambda_function_name
}

resource "aws_lambda_function" "new_lambda" {
  count = length(try([data.aws_lambda_function.existing_lambda[0].arn], [])) == 0 ? 1 : 0

  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? var.ecr_repository_uri_google_drive : var.ecr_repository_uri_s3_bucket
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

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "lambda_function_status" {
  value = length(try([data.aws_lambda_function.existing_lambda[0].arn], [])) == 1 ? "Lambda function exists" : "Lambda function created"
}

# Null resource to display a message based on the existence of the Lambda function
resource "null_resource" "lambda_status" {
  count = length(try([data.aws_lambda_function.existing_lambda[0].arn], [])) == 1 ? 1 : 0

  provisioner "local-exec" {
    command = "echo Lambda function exists"
  }
}

resource "null_resource" "lambda_creation" {
  count = length(try([data.aws_lambda_function.existing_lambda[0].arn], [])) == 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo Lambda function created"
  }
}
