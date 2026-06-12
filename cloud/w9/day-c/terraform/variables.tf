variable "aws_region" {
  description = "AWS region for the lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name prefix for AWS resources."
  type        = string
  default     = "w9-cloudwatch-alarm"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "notification_email" {
  description = "Email address used for SNS alarm notification."
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH into EC2. Use your public IP /32 for better security."
  type        = string
  default     = "0.0.0.0/0"
}

variable "cpu_alarm_threshold" {
  description = "CPU percentage threshold for CloudWatch alarm."
  type        = number
  default     = 80
}

variable "cpu_alarm_period" {
  description = "CloudWatch alarm period in seconds."
  type        = number
  default     = 300
}

variable "cpu_alarm_evaluation_periods" {
  description = "Number of evaluation periods required for alarm."
  type        = number
  default     = 1
}

