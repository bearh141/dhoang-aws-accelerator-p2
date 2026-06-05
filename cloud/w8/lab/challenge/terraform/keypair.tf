resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "challenge" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = local.common_tags
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/${var.project_name}.pem"
  content         = tls_private_key.ssh.private_key_openssh
  file_permission = "0600"
}
