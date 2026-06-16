output "my_ip_detected" {
  value = local.my_ip
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "cible_private_ip" {
  value = aws_instance.cible.private_ip
}

output "nacl_id" {
  value = aws_network_acl.td_nacl.id
}