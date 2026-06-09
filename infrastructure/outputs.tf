output "db_private_ip" {
  description = "IP privada de la instancia MySQL que consumen los backends."
  value       = aws_instance.db.private_ip
}

output "backend_despachos_repository_url" {
  description = "Repositorio ECR del backend de despachos."
  value       = aws_ecr_repository.backend_despachos.repository_url
}

output "backend_ventas_repository_url" {
  description = "Repositorio ECR del backend de ventas."
  value       = aws_ecr_repository.backend_ventas.repository_url
}

output "frontend_repository_url" {
  description = "Repositorio ECR del frontend."
  value       = aws_ecr_repository.frontend.repository_url
}
