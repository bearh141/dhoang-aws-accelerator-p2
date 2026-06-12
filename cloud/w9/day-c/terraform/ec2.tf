resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${local.name}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = local.tags
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/${local.name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0400"
}

resource "aws_instance" "monitoring_target" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user-data.sh")

  tags = merge(local.tags, {
    Name = "${local.name}-ec2"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy_attachment.ssm
  ]
}

