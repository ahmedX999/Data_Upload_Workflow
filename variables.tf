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