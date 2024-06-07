# main.tf

provider "aws" {
  region = "us-east-1"
}


variable "ecr_repository_uri_google_drive" {
  description = "The URI of the ECR repository for Google Drive"
  type        = string
  default     = "063151788650.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest"
}

variable "ecr_repository_uri_s3_bucket" {
  description = "The URI of the ECR repository for S3 Bucket"
  type        = string
  default     = "063151788650.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
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

# Import the existing IAM role
data "aws_iam_role" "existing_lambda_exec_role" {
  name = "123_123_google_drive_lambda_role"  # Replace with the existing IAM role name
}




# Lambda function resource
resource "aws_lambda_function" "my_lambda" {
  function_name = local.lambda_function_name
  role       = data.aws_iam_role.existing_lambda_exec_role.name
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? var.ecr_repository_uri_google_drive : var.ecr_repository_uri_s3_bucket
}

