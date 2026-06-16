output "bastion_public_ip" {
  value = aws_instance.td_bastion.public_ip
}

output "cible_private_ip" {
  value = aws_instance.td_cible.private_ip
}