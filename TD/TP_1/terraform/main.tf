provider "aws" {
  region = var.region
}

# Récupérer l'IP publique automatiquement
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

# Security Group Bastion
resource "aws_security_group" "bastion" {
  name        = "geogeobastion-sg"
  description = "SG bastion Geoffrey"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "geogeobastion-sg"
  }
}

# Security Group Cible
resource "aws_security_group" "cible" {
  name        = "geogeocible-sg"
  description = "SG cible Geoffrey"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "geogeocible-sg"
  }
}

# Instance Bastion
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "geogeobastion"
  }
}

# Instance Cible
resource "aws_instance" "cible" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.cible.id]
  associate_public_ip_address = false

  tags = {
    Name = "geogeocible"
  }
}

# NACL
resource "aws_network_acl" "td_nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = [var.subnet_id]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.my_ip
    from_port  = 22
    to_port    = 22
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "td-nacl-geogeo"
  }
}