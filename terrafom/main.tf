provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "geoffrey_sg" {
  name   = "geoffrey_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "geoffrey_sg"
  }
}

resource "aws_subnet" "geoffrey_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "172.31.201.0/24"

  tags = {
    Name = "geoffrey_subnet"
  }
}

resource "aws_key_pair" "geoffrey_kp" {
  key_name   = "geoffrey_kp"
  public_key = file("/home/geoffrey/.ssh/id_rsa.pub")
}

resource "aws_instance" "geoffrey_serverweb" {
  ami                         = var.vm_image
  key_name                    = aws_key_pair.geoffrey_kp.key_name
  instance_type               = var.vm_instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.geoffrey_subnet.id
  vpc_security_group_ids      = [aws_security_group.geoffrey_sg.id]

  tags = {
    Name = "geoffrey_serverweb"
  }
}
