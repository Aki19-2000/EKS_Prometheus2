resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  version = var.cluster_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnets

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  ami_type        = "AL2_x86_64" # Use the appropriate AMI type for your instance type
  release_version = "ami-0d36889d628f44a78" # Replace with the actual release version

  instance_types = [var.instance_type]

  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks_cluster.name}
EOT
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}

resource "null_resource" "verify_kubernetes" {
  provisioner "local-exec" {
    command = <<EOT
kubectl get nodes
EOT
    environment = {
      KUBECONFIG = "${path.module}/kubeconfig"
    }
  }

  depends_on = [
    null_resource.update_kubeconfig,
  ]
}

resource "kubernetes_deployment" "patient_service" {
  metadata {
    name = "patient-service"
    labels = {
      app = "patient-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "patient-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "patient-service"
        }
      }

      spec {
        container {
          image = var.patient_image
          name  = "patient-service"

          port {
            container_port = 3000
          }
        }
      }
    }
  }

  depends_on = [
    null_resource.verify_kubernetes,
  ]
}

resource "kubernetes_deployment" "appointment_service" {
  metadata {
    name = "appointment-service"
    labels = {
      app = "appointment-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "appointment-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "appointment-service"
        }
      }

      spec {
        container {
          image = var.appointment_image
          name  = "appointment-service"

          port {
            container_port = 3000
          }
        }
      }
    }
  }

  depends_on = [
    null_resource.verify_kubernetes,
  ]
}

resource "kubernetes_service" "patient_service" {
  metadata {
    name = "patient-service"
  }

  spec {
    selector = {
      app = "patient-service"
    }

    port {
      protocol = "TCP"
      port     = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }

  depends_on = [
    null_resource.verify_kubernetes,
  ]
}

resource "kubernetes_service" "appointment_service" {
  metadata {
    name = "appointment-service"
  }

  spec {
    selector = {
      app = "appointment-service"
    }

    port {
      protocol = "TCP"
      port     = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }

  depends_on = [
    null_resource.verify_kubernetes,
  ]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"

  create_namespace = true

  depends_on = [
    null_resource.verify_kubernetes,
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"

  create_namespace = true

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [
    null_resource.verify_kubernetes,
  ]
}
