# ─── Metric Filter para errores en logs de EKS ────────────────────────

resource "aws_cloudwatch_log_metric_filter" "eks_errors" {
  name           = "${var.project_name}-eks-errors"
  pattern        = "?ERROR ?Exception ?Error"
  log_group_name = aws_cloudwatch_log_group.eks.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = var.project_name
    value     = "1"
  }
}

# ─── Alarma EKS ───────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "eks_errors" {
  alarm_name          = "${var.project_name}-eks-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = var.project_name
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarma si hay mas de 10 errores en logs de EKS en 5 minutos"
}

# ─── Alarmas EC2 (MySQL) ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarma si CPU de MySQL supera 80% por 10 minutos"
  dimensions = {
    InstanceId = aws_instance.db.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "${var.project_name}-ec2-status-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Alarma si el status check de MySQL falla"
  dimensions = {
    InstanceId = aws_instance.db.id
  }
}

# ─── Dashboard ────────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.db.id],
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.db.id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 MySQL - CPU y Status"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "node_ready_count", "ClusterName", aws_eks_cluster.main.name],
            [var.project_name, "ErrorCount"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS - Nodos Ready y Errores"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          query  = "SOURCE '/aws/eks/${var.eks_cluster_name}/cluster' | fields @timestamp, @logStream, @message | filter @message like /ERROR|Exception/ | sort @timestamp desc | limit 20"
          region = var.aws_region
          title  = "Ultimos errores en EKS"
        }
      }
    ]
  })
}
