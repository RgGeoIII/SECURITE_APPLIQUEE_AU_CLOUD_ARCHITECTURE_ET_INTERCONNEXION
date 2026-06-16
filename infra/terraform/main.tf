provider "aws" {
    region = var.aws_region
}

# Security Group : Bastion
resource "aws_security_group" "xavbastion-sg" {
    name        = "xavbastion-sg"
    description = "SSH depuis mon IP uniquement"
    vpc_id      = var.vpc_id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Security Group : Cible
resource "aws_security_group" "xavcible-sg" {
    name        = "xavcible-sg"
    description = "SSH et ICMP uniquement depuis le bastion"
    vpc_id      = var.vpc_id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.xavbastion-sg.id]
    }

    ingress {
        from_port       = -1
        to_port         = -1
        protocol        = "icmp"
        security_groups = [aws_security_group.xavbastion-sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Sous-réseau
resource "aws_subnet" "td1" {
    vpc_id     = var.vpc_id
    cidr_block = "172.31.190.0/24"
}

# Instance Bastion (IP publique)
resource "aws_instance" "td_bastion" {
    ami                         = var.vm_image
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = aws_subnet.td1.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.xavbastion-sg.id]

    tags = {
        Name = "td-bastion"
    }
}

# Instance Cible (sans IP publique)
resource "aws_instance" "td_cible" {
    ami                         = var.vm_image
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = aws_subnet.td1.id
    associate_public_ip_address = false
    vpc_security_group_ids      = [aws_security_group.xavcible-sg.id]

    tags = {
        Name = "td-cible"
    }
}

# NACL td-nacl
resource "aws_network_acl" "td_nacl" {
    vpc_id     = var.vpc_id
    subnet_ids = [aws_subnet.td1.id]

    # Règle entrante : SSH depuis mon IP uniquement
    ingress {
        rule_no    = 100
        protocol   = "tcp"
        from_port  = 22
        to_port    = 22
        cidr_block = var.my_ip
        action     = "allow"
    }

    # Règle sortante : ports éphémères (trafic retour SSH)
    egress {
        rule_no    = 100
        protocol   = "tcp"
        from_port  = 1024
        to_port    = 65535
        cidr_block = "0.0.0.0/0"
        action     = "allow"
    }

    tags = {
        Name = "td-nacl"
    }
}
