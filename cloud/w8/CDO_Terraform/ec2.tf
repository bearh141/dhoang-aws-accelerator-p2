data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
    db_endpoint  = aws_db_instance.mysql.address
    db_name      = var.db_name
    s3_bucket    = aws_s3_bucket.assets.bucket
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web"
  })
}
