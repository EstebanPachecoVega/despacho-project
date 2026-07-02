data "aws_caller_identity" "current" {}

output "aws_account_id" {
  description = "ID de la cuenta AWS."
  value       = data.aws_caller_identity.current.account_id
}

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

output "private_subnet_ids" {
  description = "IDs de las subredes privadas."
  value       = [aws_subnet.private.id, aws_subnet.private_2.id]
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas."
  value       = [aws_subnet.public.id, aws_subnet.public_2.id]
}

output "nat_gateway_ip" {
  description = "IP pública del NAT Gateway."
  value       = aws_eip.nat.public_ip
}
