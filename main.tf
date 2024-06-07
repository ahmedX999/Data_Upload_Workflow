provider "aws" {
  region = "us-east-1"
}

variable "user_id" {
  description = "The user ID"
  type        = string
}

variable "instance_id" {
  description = "The instance ID"
  type        = string
}

variable "instance_type" {
  description = "The instance type"
  type        = string
}

variable "ecr_repository_uri_google_drive" {
  description = "The URI of the ECR repository for Google Drive"
  type        = string
  default     = "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest"
}

variable "ecr_repository_uri_s3_bucket" {
  description = "The URI of the ECR repository for S3 Bucket"
  type        = string
  default     = "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
}

locals {
  lambda_function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
}



locals {
  lambda_exists = data.external.lambda_check.result.result == "exists"
}

resource "aws_lambda_function" "new_lambda" {
  count = local.lambda_exists ? 0 : 1

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
  value = local.lambda_exists ? "Lambda function exists" : "Lambda function created"
}

output "lambda_function_name" {
  value = local.lambda_function_name
}

resource "null_resource" "lambda_status" {
  count = local.lambda_exists ? 1 : 0

  provisioner "local-exec" {
    command = "echo Lambda function exists"
  }
}

resource "null_resource" "lambda_creation" {
  count = local.lambda_exists ? 0 : 1

  provisioner "local-exec" {
    command = "echo Lambda function created"
  }
}
