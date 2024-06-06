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

data "aws_lambda_function" "existing_lambda" {
  count         = 1
  function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
}

resource "aws_iam_role" "lambda_exec_role" {
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

resource "aws_lambda_function" "lambda_function" {
  count                   = length(data.aws_lambda_function.existing_lambda.*.function_name) == 0 ? 1 : 0
  function_name           = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
  role                    = aws_iam_role.lambda_exec_role.arn
  package_type            = "Image"
  image_uri               = var.instance_type == "google_drive" ? "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest" : "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
