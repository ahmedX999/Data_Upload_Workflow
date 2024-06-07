# main.tf

provider "aws" {
  region = "us-east-1"
}

variable "user_id" {
  description = "ID of the user"
  type        = string
}

variable "instance_id" {
  description = "ID of the instance"
  type        = string
}

variable "instance_type" {
  description = "Type of instance: google_drive or s3"
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

# External data source to check Lambda function existence
data "external" "lambda_check" {
  program = ["bash", "${path.module}/check_lambda.sh", var.user_id, var.instance_id, var.instance_type]
}

# Local variable to determine if Lambda function exists
locals {
  lambda_function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
  lambda_exists        = data.external.lambda_check.result == "true"
}

# Lambda function resource
resource "aws_lambda_function" "new_lambda" {
  count = local.lambda_exists ? 0 : 1

  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? var.ecr_repository_uri_google_drive : var.ecr_repository_uri_s3_bucket
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM role policy attachment
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Outputs
output "lambda_function_status" {
  value = local.lambda_exists ? "Lambda function exists" : "Lambda function created"
}

output "lambda_function_name" {
  value = local.lambda_function_name
}
