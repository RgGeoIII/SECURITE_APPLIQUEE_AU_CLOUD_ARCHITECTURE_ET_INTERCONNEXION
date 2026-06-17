resource "aws_security_group" "sonde" {
  name   = "${local.prefix}-sonde"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "SSH depuis le bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  ingress {
    description     = "ICMP depuis le bastion"
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
    Name = "${local.prefix}-sonde"
  }
}

resource "aws_instance" "sonde" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.vm_instance_type
  subnet_id                   = data.aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.sonde.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ludo_key.key_name

  user_data = <<-EOT
#!/bin/bash
apt-get update -y
apt-get install -y software-properties-common
add-apt-repository -y ppa:oisf/suricata-stable
apt-get update -y
apt-get install -y suricata
suricata-update
echo 'alert icmp any any -> $HOME_NET any (msg:"TD2 ICMP detecte"; sid:1000001; rev:1;)' >> /var/lib/suricata/rules/suricata.rules
systemctl enable suricata
systemctl restart suricata
EOT

  tags = {
    Name = "${local.prefix}-sonde"
  }
}