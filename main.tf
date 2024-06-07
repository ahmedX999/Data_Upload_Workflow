# main.tf

provider "aws" {
  region = "us-east-1"
}


variable "ecr_repository_uri_google_drive" {
  description = "The URI of the ECR repository for Google Drive"
  type        = string
  default     = "${var.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest"
}

variable "ecr_repository_uri_s3_bucket" {
  description = "The URI of the ECR repository for S3 Bucket"
  type        = string
  default     = "${var.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
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

locals {
  lambda_function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
  lambda_function_role_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda_role"
}


# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_exec_role" {
  name = local.lambda_function_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to IAM role
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function resource
resource "aws_lambda_function" "my_lambda" {
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? var.ecr_repository_uri_google_drive : var.ecr_repository_uri_s3_bucket
}

