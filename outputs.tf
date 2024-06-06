output "lambda_function_name" {
  value = length(data.aws_lambda_function.existing_lambda) > 0 ? aws_lambda_function.lambda_function[0].function_name : null
}