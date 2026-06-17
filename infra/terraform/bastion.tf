resource "aws_security_group" "td2-bastion-sg" {
    name        = "td2-27-sg-bastion"
    description = "SSH depuis mon IP uniquement"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description = "SSH"
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

    tags = {
        Name = "td2-27-sg-bastion"
    }
}

resource "aws_instance" "td2-bastion" {
    ami                         = var.vm_image
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = data.aws_subnet.public_a.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.td2-bastion-sg.id]

    tags = {
        Name = "td2-27-bastion"
    }
}

output "td2_bastion_ip" {
    value = aws_instance.td2-bastion.public_ip
}
