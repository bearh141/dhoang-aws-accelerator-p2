variable "aws_region" {
  description = "AWS region for the challenge infrastructure."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix used for AWS resource names and tags."
  type        = string
  default     = "w8-k8s-challenge"
}

variable "instance_type" {
  description = "EC2 instance type. minikube needs more memory than a tiny instance."
  type        = string
  default     = "t3.small"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH to the EC2 instance for debugging. Change this to your public IP /32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "node_port" {
  description = "Kubernetes NodePort exposed on the EC2 instance and targeted by ALB."
  type        = number
  default     = 30080
}
