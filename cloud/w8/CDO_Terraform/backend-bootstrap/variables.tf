variable "aws_region" {
  description = "AWS region used to create backend resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name prefix for backend resources."
  type        = string
  default     = "w8-cdo-webapp"
}
