# Sous-réseau privé
resource "aws_subnet" "td2-private" {
    vpc_id            = data.aws_vpc.default.id
    cidr_block        = "172.31.127.0/24"
    availability_zone = "eu-west-3a"

    tags = {
        Name = "td2-27-prive"
    }
}

# IP élastique pour la NAT Gateway
resource "aws_eip" "td2-nat" {
    domain = "vpc"

    tags = {
        Name = "td2-27-eip"
    }
}

# NAT Gateway : placée dans le sous-réseau PUBLIC
resource "aws_nat_gateway" "td2-nat" {
    allocation_id = aws_eip.td2-nat.id
    subnet_id     = data.aws_subnet.public_a.id

    tags = {
        Name = "td2-27-nat"
    }
}

# Table de routage privée : route vers la NAT Gateway
resource "aws_route_table" "td2-private" {
    vpc_id = data.aws_vpc.default.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.td2-nat.id
    }

    tags = {
        Name = "td2-27-rt-prive"
    }
}

# Association table de routage avec sous-réseau privé
resource "aws_route_table_association" "td2-private" {
    subnet_id      = aws_subnet.td2-private.id
    route_table_id = aws_route_table.td2-private.id
}

# Security Group : instance privée
resource "aws_security_group" "td2-private-sg" {
    name        = "td2-27-sg-prive"
    description = "SSH depuis le bastion TD2 uniquement"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description     = "SSH depuis le bastion"
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.td2-bastion-sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "td2-27-sg-prive"
    }
}

# Instance privée
resource "aws_instance" "td2-private" {
    ami                         = var.vm_image
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = aws_subnet.td2-private.id
    associate_public_ip_address = false
    vpc_security_group_ids      = [aws_security_group.td2-private-sg.id]

    tags = {
        Name = "td2-27-prive"
    }
}

output "td2_private_ip" {
    value       = aws_instance.td2-private.private_ip
    description = "IP privee de l instance privee TD2"
}
