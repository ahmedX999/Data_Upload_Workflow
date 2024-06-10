provider "aws" {
  region = "us-east-1"
}

variable "ecr_repository_uri_google_drive" {
  description = "The URI of the ECR repository for Google Drive"
  type        = string
  default     = "975050103916.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest"
}

variable "ecr_repository_uri_s3_bucket" {
  description = "The URI of the ECR repository for S3 Bucket"
  type        = string
  default     = "975050103916.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
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

# Generate a random string for unique naming
resource "random_string" "lambda_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  lambda_function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
  iam_role_name        = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda_role"
}

# Check if IAM role already exists
data "aws_iam_role" "existing_lambda_exec_role" {
  name = local.iam_role_name
  # If the role does not exist, ignore errors
  depends_on = [aws_iam_role.lambda_exec_role]
}

resource "aws_iam_role" "lambda_exec_role" {
  count = data.aws_iam_role.existing_lambda_exec_role.arn != "" ? 0 : 1
  name  = local.iam_role_name

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
  count      = data.aws_iam_role.existing_lambda_exec_role.arn != "" ? 0 : 1
  role       = local.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Check if Lambda function already exists
data "aws_lambda_function" "existing_lambda_function" {
  function_name = local.lambda_function_name
  # If the function does not exist, ignore errors
  depends_on = [aws_lambda_function.my_lambda]
}

# Lambda function resource
resource "aws_lambda_function" "my_lambda" {
  count         = data.aws_lambda_function.existing_lambda_function.arn != "" ? 0 : 1
  function_name = local.lambda_function_name
  role          = data.aws_iam_role.existing_lambda_exec_role.arn != "" ? data.aws_iam_role.existing_lambda_exec_role.arn : aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? var.ecr_repository_uri_google_drive : var.ecr_repository_uri_s3_bucket
}
