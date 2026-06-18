output "site_url" {
  value       = "http://${aws_lb.public.dns_name}"
  description = "URL du formulaire d'inscription"
}

output "internal_alb_dns" {
  value       = aws_lb.internal.dns_name
  description = "DNS de l'ALB interne (joignable uniquement depuis le VPC)"
}
