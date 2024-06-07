provider "aws" {
  region = "us-east-1"
}


variable "lambda_function_exists" {
  default = length(data.aws_lambda_function.existing_lambda) > 0
}

// Create IAM role, Lambda function, and policy attachment conditionally based on the existence of the Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  count = var.lambda_function_exists ? 0 : 1

  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "lambda_function" {
  count = var.lambda_function_exists ? 0 : 1

  function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
  role          = aws_iam_role.lambda_exec_role[count.index].arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest" : "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  count = var.lambda_function_exists ? 0 : 1

  role       = aws_iam_role.lambda_exec_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// Output the Lambda function name if it exists, otherwise output null
output "lambda_function_name" {
  value = var.lambda_function_exists ? null : aws_lambda_function.lambda_function[0].function_name
}
