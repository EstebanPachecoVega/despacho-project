# EKS Cluster

resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = data.aws_iam_role.lab.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = [aws_subnet.public.id, aws_subnet.public_2.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }
}

# EKS Node Group

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = data.aws_iam_role.lab.arn
  subnet_ids      = [aws_subnet.public.id, aws_subnet.public_2.id]

  scaling_config {
    desired_size = var.eks_desired_size
    min_size     = var.eks_min_size
    max_size     = var.eks_max_size
  }

  instance_types = [var.eks_node_instance_type]

  tags = {
    Name = "${var.project_name}-eks-node"
  }
}

# EKS Addons

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}
