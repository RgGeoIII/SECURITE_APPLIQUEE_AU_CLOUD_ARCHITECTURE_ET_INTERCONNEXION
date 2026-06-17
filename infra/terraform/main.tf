provider "aws" {
    region = var.aws_region
}

# Security Group : Bastion
resource "aws_security_group" "xavier-bastion-sg" {
    name        = "xavier-bastion-sg"
    description = "SSH depuis mon IP uniquement"
    vpc_id      = var.vpc_id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
    from_port   = 80
    to_port     = 80
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

# Security Group : Cible
resource "aws_security_group" "xavier-cible-sg" {
    name        = "xavier-cible-sg"
    description = "SSH et ICMP uniquement depuis le bastion"
    vpc_id      = var.vpc_id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.xavier-bastion-sg.id]
    }

    ingress {
        from_port       = -1
        to_port         = -1
        protocol        = "icmp"
        security_groups = [aws_security_group.xavier-bastion-sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Sous-réseau
resource "aws_subnet" "xavier-subnet" {
    vpc_id     = var.vpc_id
    cidr_block = "172.31.190.0/24"

    tags = {
        Name = "xavier-subnet"
    }
}

# Instance Bastion (IP publique)
resource "aws_instance" "xavier-bastion" {
    ami                         = var.vm_image
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = aws_subnet.xavier-subnet.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.xavier-bastion-sg.id]

    tags = {
        Name = "xavier-bastion"
    }
}

# Instance Cible (sans IP publique)
resource "aws_instance" "xavier-cible" {
    ami                         = var.vm_image
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = aws_subnet.xavier-subnet.id
    associate_public_ip_address = false
    vpc_security_group_ids      = [aws_security_group.xavier-cible-sg.id]

    tags = {
        Name = "xavier-cible"
    }
}

# NACL xavier-nacl
resource "aws_network_acl" "xavier-nacl" {
    vpc_id     = var.vpc_id
    subnet_ids = [aws_subnet.xavier-subnet.id]

    # Règle entrante n°100 : allow SSH depuis mon IP
    ingress {
        rule_no    = 100
        protocol   = "tcp"
        from_port  = 22
        to_port    = 22
        cidr_block = var.my_ip
        action     = "allow"
    }

    ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    }

    # Règle entrante n°200 : ports éphémères (réponses apt update)
    ingress {
        rule_no    = 200
        protocol   = "tcp"
        from_port  = 1024
        to_port    = 65535
        cidr_block = "0.0.0.0/0"
        action     = "allow"
    }

    # Règle sortante n°90 : HTTP pour apt update
    egress {
        rule_no    = 90
        protocol   = "tcp"
        from_port  = 80
        to_port    = 80
        cidr_block = "0.0.0.0/0"
        action     = "allow"
    }

    # Règle sortante n°91 : HTTPS pour apt update
    egress {
        rule_no    = 91
        protocol   = "tcp"
        from_port  = 443
        to_port    = 443
        cidr_block = "0.0.0.0/0"
        action     = "allow"
    }

    # Règle sortante n°100 : ports éphémères (trafic retour SSH)
    egress {
        rule_no    = 100
        protocol   = "tcp"
        from_port  = 1024
        to_port    = 65535
        cidr_block = "0.0.0.0/0"
        action     = "allow"
    }

    tags = {
        Name = "xavier-nacl"
    }
}