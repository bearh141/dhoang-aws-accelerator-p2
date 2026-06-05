resource "aws_instance" "k8s" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.challenge.key_name

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user-data.sh", {
    node_port = var.node_port
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-minikube"
  })
}
