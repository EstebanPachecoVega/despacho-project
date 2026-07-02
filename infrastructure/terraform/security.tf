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
