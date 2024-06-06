// Define a local variable to check if the Lambda function exists
locals {
  lambda_function_exists = length(data.aws_lambda_function.existing_lambda) > 0
}

// Define IAM role, Lambda function, and policy attachment conditionally based on the existence of the Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  count = local.lambda_function_exists ? 0 : 1

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
  count = local.lambda_function_exists ? 0 : 1

  function_name = "${var.user_id}_${var.instance_id}_${var.instance_type}_lambda"
  role          = aws_iam_role.lambda_exec_role[0].arn
  package_type  = "Image"
  image_uri     = var.instance_type == "google_drive" ? "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-google-drive:latest" : "aws_account_id.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-s3-bucket:latest"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  count = local.lambda_function_exists ? 0 : 1

  role       = aws_iam_role.lambda_exec_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
