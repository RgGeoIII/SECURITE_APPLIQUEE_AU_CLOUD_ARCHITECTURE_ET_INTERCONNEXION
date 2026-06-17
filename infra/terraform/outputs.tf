output "bastion_public_ip" {
  value = aws_instance.boris-serverwebludo.public_ip
}

output "cible_private_ip" {
  value = aws_instance.td_cible.private_ip
}
output "sonde_private_ip" {
  value = aws_instance.sonde.private_ip
}

output "sonde_public_ip" {
  value = aws_instance.sonde.public_ip
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}
