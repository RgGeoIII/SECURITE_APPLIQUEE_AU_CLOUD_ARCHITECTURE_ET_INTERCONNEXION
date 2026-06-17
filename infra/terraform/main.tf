provider "aws" {
  region = var.aws_region

}
/*
resource "aws_security_group" "bars_sg" {
  name   = "bars_sg_ludo"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
*/
resource "aws_subnet" "boris-servers-subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "172.31.90.0/24"

  tags = {
    Name = "boris-servers-subnet"
  }



}

resource "aws_key_pair" "ludo_key" {
  key_name   = "ludo_key"
  public_key = file("~/.ssh/ludo_aws_key.pub")
}


resource "aws_instance" "boris-serverwebludo" {
  ami                         = var.vm_image
  key_name                    = aws_key_pair.ludo_key.key_name
  instance_type               = var.vm_instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]
  subnet_id                   = aws_subnet.boris-servers-subnet.id

  tags = {
    Name = "td-bastion-ludo"
  }
}

resource "aws_security_group" "sg_bastion" {
  name   = "bastion-ludo"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH depuis mon IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Tout autoriser en sortie"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-ludo"
  }
}

resource "aws_security_group" "sg_cible" {
  name   = "cible-ludo"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "SSH depuis le bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  ingress {
    description     = "Ping depuis le bastion"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    description = "Tout autoriser en sortie"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cible-ludo"
  }
}
resource "aws_instance" "td_cible" {
  ami                         = var.vm_image
  key_name                    = aws_key_pair.ludo_key.key_name
  instance_type               = var.vm_instance_type
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg_cible.id]
  subnet_id                   = aws_subnet.private.id

  tags = {
    Name = "td-cible-ludo"
  }
}