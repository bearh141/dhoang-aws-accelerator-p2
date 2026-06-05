output "alb_dns_name" {
  description = "Open this URL in the browser after the target group becomes healthy."
  value       = "http://${aws_lb.app.dns_name}"
}

output "ec2_public_ip" {
  description = "EC2 public IP for emergency SSH/debugging."
  value       = aws_instance.k8s.public_ip
}

output "ssh_private_key_path" {
  description = "Generated private key path for SSH debugging."
  value       = local_sensitive_file.private_key.filename
}

output "ssh_command" {
  description = "SSH command for debugging the EC2 instance."
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ubuntu@${aws_instance.k8s.public_ip}"
}
