terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "main" {
  name   = "${var.project_name}-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "mysql_internal" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main.id
  source_security_group_id = aws_security_group.main.id
}

# ECR Repositories
resource "aws_ecr_repository" "backend_despachos" {
  name         = "${var.project_name}-backend-despachos"
  force_delete = true
}
resource "aws_ecr_repository" "backend_ventas" {
  name         = "${var.project_name}-backend-ventas"
  force_delete = true
}
resource "aws_ecr_repository" "frontend" {
  name         = "${var.project_name}-frontend"
  force_delete = true
}

# EC2 MySQL
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.db_volume_size
    volume_type           = "gp3"
    delete_on_termination = false
    tags = {
      Name = "${var.project_name}-mysql-data"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    MYSQL_DATA_DIR="/var/lib/mysql"
    MYSQL_DEVICE=""

    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    until docker info > /dev/null 2>&1; do sleep 3; done

    for device in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
      if [ -b "$device" ]; then
        MYSQL_DEVICE="$device"
        break
      fi
    done

    if [ -z "$MYSQL_DEVICE" ]; then
      echo "No se encontro el volumen persistente para MySQL" >&2
      exit 1
    fi

    if ! blkid "$MYSQL_DEVICE" > /dev/null 2>&1; then
      mkfs -t xfs "$MYSQL_DEVICE"
    fi

    mkdir -p "$MYSQL_DATA_DIR"
    if ! mountpoint -q "$MYSQL_DATA_DIR"; then
      mount "$MYSQL_DEVICE" "$MYSQL_DATA_DIR"
    fi

    MYSQL_DEVICE_UUID="$(blkid -s UUID -o value "$MYSQL_DEVICE")"
    if ! grep -q "$MYSQL_DEVICE_UUID" /etc/fstab; then
      echo "UUID=$MYSQL_DEVICE_UUID $MYSQL_DATA_DIR xfs defaults,nofail 0 2" >> /etc/fstab
    fi

    docker system prune -af
    docker rm -f mysql || true
    docker run -d \
    --name mysql \
    -e MYSQL_ROOT_PASSWORD=${var.db_root_password} \
    -e MYSQL_DATABASE=${var.db_name} \
    -e MYSQL_USER=${var.db_username} \
    -e MYSQL_PASSWORD=${var.db_password} \
    -e MYSQL_ROOT_HOST=% \
    -p 3306:3306 \
    -v /var/lib/mysql:/var/lib/mysql \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    mysql:8-oracle \
    --bind-address=0.0.0.0 \
    --performance-schema=OFF
  EOF

  tags = { Name = "${var.project_name}-mysql" }
}

# CloudWatch
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

data "aws_iam_role" "lab" {
  name = "LabRole"
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = data.aws_iam_role.lab.arn
  task_role_arn            = null

  container_definitions = jsonencode([
    {
      name         = "backend-despachos"
      image        = "${aws_ecr_repository.backend_despachos.repository_url}:latest"
      portMappings = [{ containerPort = 8080 }]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/swagger-ui.html || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 5
        startPeriod = 180
      }
      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${aws_instance.db.private_ip}:3306/${var.db_name}?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true" },
        { name = "SPRING_DATASOURCE_USERNAME", value = var.db_username },
        { name = "SPRING_DATASOURCE_PASSWORD", value = var.db_password },
        { name = "DB_HOST", value = aws_instance.db.private_ip }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend-despachos"
        }
      }
    },
    {
      name         = "backend-ventas"
      image        = "${aws_ecr_repository.backend_ventas.repository_url}:latest"
      portMappings = [{ containerPort = 8081 }]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8081/swagger-ui.html || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 5
        startPeriod = 180
      }
      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${aws_instance.db.private_ip}:3306/${var.db_name}?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true" },
        { name = "SPRING_DATASOURCE_USERNAME", value = var.db_username },
        { name = "SPRING_DATASOURCE_PASSWORD", value = var.db_password },
        { name = "DB_HOST", value = aws_instance.db.private_ip }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend-ventas"
        }
      }
    },
    {
      name         = "frontend"
      image        = "${aws_ecr_repository.frontend.repository_url}:latest"
      portMappings = [{ containerPort = 80 }]
      dependsOn = [
        { containerName = "backend-despachos", condition = "START" },
        { containerName = "backend-ventas", condition = "START" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  force_new_deployment               = true
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
}
