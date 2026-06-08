output "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state."
  value       = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  value       = aws_dynamodb_table.lock.name
}

output "backend_config_example" {
  description = "Backend block values for the main project."
  value = {
    bucket         = aws_s3_bucket.state.bucket
    key            = "w8/cdo-terraform/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.lock.name
    encrypt        = true
  }
}
