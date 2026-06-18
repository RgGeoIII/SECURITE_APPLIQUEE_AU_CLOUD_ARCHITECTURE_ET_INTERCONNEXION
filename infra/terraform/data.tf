# Lecture du VPC par défaut (data source = jamais supprimé par Terraform)
data "aws_vpc" "default" {
  default = true
}

# Sous-réseau public en eu-west-3a (référencé directement par son ID)
data "aws_subnet" "public_a" {
  id = "subnet-095c2c562da7511cc"
}

# AMI Ubuntu 22.04 la plus récente (pour Suricata)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# Préfixe unique basé sur le numéro d'étudiant
locals {
  prefix = "td2-27"
}
