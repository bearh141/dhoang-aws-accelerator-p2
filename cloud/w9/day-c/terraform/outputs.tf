output "account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

output "ec2_instance_id" {
  description = "EC2 instance ID monitored by CloudWatch alarm."
  value       = aws_instance.monitoring_target.id
}

output "ec2_public_ip" {
  description = "Public IP for SSH."
  value       = aws_instance.monitoring_target.public_ip
}

output "ssh_private_key_path" {
  description = "Local private key path."
  value       = local_sensitive_file.private_key.filename
}

output "sns_topic_arn" {
  description = "SNS topic ARN used by alarm."
  value       = aws_sns_topic.cpu_alarm.arn
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch alarm name."
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "cloudtrail_name" {
  description = "CloudTrail trail used to capture root account login events."
  value       = aws_cloudtrail.root_login.name
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch Logs group receiving CloudTrail events."
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "root_login_metric_filter_name" {
  description = "CloudWatch Logs metric filter for root account login events."
  value       = aws_cloudwatch_log_metric_filter.root_account_login.name
}

output "root_login_alarm_name" {
  description = "CloudWatch alarm name for AWS root account login."
  value       = aws_cloudwatch_metric_alarm.root_account_login.alarm_name
}

output "ssh_command" {
  description = "SSH command to connect to EC2."
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ubuntu@${aws_instance.monitoring_target.public_ip}"
}
