output "bastion_public_ip" {
  value = aws_instance.xavier-bastion.public_ip
}

output "cible_private_ip" {
  value = aws_instance.xavier-cible.private_ip
}