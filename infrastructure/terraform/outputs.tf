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

output "eks_cluster_name" {
  description = "Nombre del cluster EKS."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del cluster EKS."
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca_cert" {
  description = "Certificado CA del cluster EKS."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}
