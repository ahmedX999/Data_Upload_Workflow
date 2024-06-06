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
