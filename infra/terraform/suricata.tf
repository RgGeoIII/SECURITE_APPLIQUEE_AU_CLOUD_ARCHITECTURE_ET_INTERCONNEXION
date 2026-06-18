# ── TD2 : Sonde Suricata (IDS) via user_data ─────────────────────────

# Security Group : sonde Suricata
resource "aws_security_group" "td2-sonde-sg" {
    name        = "td2-27-sg-sonde"
    description = "SSH et ICMP depuis le bastion TD2"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description     = "SSH depuis le bastion"
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.td2-bastion-sg.id]
    }

    ingress {
        description     = "ICMP depuis le bastion"
        from_port       = -1
        to_port         = -1
        protocol        = "icmp"
        security_groups = [aws_security_group.td2-bastion-sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "td2-27-sg-sonde"
    }
}

# Instance Suricata — installée automatiquement via user_data
resource "aws_instance" "td2-sonde" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = var.vm_instance_type
    key_name                    = var.key_name
    subnet_id                   = data.aws_subnet.public_a.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.td2-sonde-sg.id]

    # Script exécuté au premier démarrage — installe et configure Suricata
    user_data = <<-EOT
        #!/bin/bash
        add-apt-repository -y ppa:oisf/suricata-stable
        apt-get update && apt-get install -y suricata
        suricata-update

        # Correction : l'interface réseau sur AWS est ens5 et non eth0
        sed -i 's/interface: eth0/interface: ens5/g' /etc/suricata/suricata.yaml

        echo 'alert icmp any any -> $HOME_NET any (msg:"TD2 ICMP detecte"; sid:1000001; rev:1;)' \
            >> /var/lib/suricata/rules/suricata.rules

        systemctl enable suricata
        systemctl restart suricata
    EOT

    tags = {
        Name = "td2-27-sonde"
    }
}

output "td2_sonde_private_ip" {
    value       = aws_instance.td2-sonde.private_ip
    description = "IP privee de la sonde Suricata"
}