# ─── Security Group de la base de datos MySQL (privado) ───────────────

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "SG de la base de datos MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private.cidr_block, aws_subnet.private_2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─── Regla de health check del LoadBalancer para EKS ─────────────────
# Permite al Classic Load Balancer acceder a los NodePorts en los nodos worker

resource "aws_security_group_rule" "eks_lb_health" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Permitir health checks del LoadBalancer en NodePorts"
}
