resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  version = "1.25" # Ensure this is a supported version

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name   = aws_eks_cluster.eks.name
  node_role_arn  = var.node_role_arn
  subnet_ids     = var.subnets
  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }

  ami_type        = "AL2_x86_64" # Use the appropriate AMI type for your instance type
  release_version = "ami-0a0b0c0d0e0f0g0h0" # Replace with the actual AMI ID for Kubernetes version 1.25

  tags = {
    Name = "${var.cluster_name}-worker-nodes"
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "kubernetes_deployment" "AppointmentDeployment" {
  metadata {
    name      = "appointment-deployment"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "appointment" }
    }

    template {
      metadata { labels = { app = "appointment" } }

      spec {
        container {
          name  = "appointment-container"
          image = var.appointment_image

          port {
            container_port = 3001
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "AppointmentService" {
  metadata {
    name      = "appointment-service"
    namespace = "default"
  }

  spec {
    selector = { app = "appointment" }

    port {
      protocol   = "TCP"
      port       = 3001
      target_port = 3001
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.AppointmentDeployment]
}

resource "kubernetes_deployment" "PatientDeployment" {
  metadata {
    name      = "patient-deployment"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "patient" }
    }

    template {
      metadata { labels = { app = "patient" } }

      spec {
        container {
          name  = "patient-container"
          image = var.patient_image

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "PatientService" {
  metadata {
    name      = "patient-service"
    namespace = "default"
  }

  spec {
    selector = { app = "patient" }

    port {
      protocol   = "TCP"
      port       = 3000
      target_port = 3000
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.PatientDeployment]
}
