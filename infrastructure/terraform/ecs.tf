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
  memory                   = "4096"
  execution_role_arn       = data.aws_iam_role.lab.arn
  task_role_arn            = null

  container_definitions = jsonencode([
    {
      name         = "backend-despachos"
      image        = "${aws_ecr_repository.backend_despachos.repository_url}:latest"
      portMappings = [{ containerPort = 8080 }]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -sf http://localhost:8080/actuator/health || exit 1"]
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
        command     = ["CMD-SHELL", "curl -sf http://localhost:8081/actuator/health || exit 1"]
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
      environment = [
        { name = "BACKEND_DESPACHOS_HOST", value = "localhost" },
        { name = "BACKEND_DESPACHOS_PORT", value = "8080" },
        { name = "BACKEND_VENTAS_HOST", value = "localhost" },
        { name = "BACKEND_VENTAS_PORT", value = "8081" }
      ]
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
