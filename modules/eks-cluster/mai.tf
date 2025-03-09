provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  token                  = data.aws_eks_cluster_auth.eks.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    token                  = data.aws_eks_cluster_auth.eks.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = jsonencode([
      {
        rolearn  = var.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    mapUsers = jsonencode([
      {
        userarn  = "arn:aws:iam::302263075199:user/Pavithra"
        username = "Pavithra"
        groups   = ["system:masters"]
      }
    ])
  }
}

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
    subnet_ids         = var.private_subnets
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  #version = var.cluster_version

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name   = aws_eks_cluster.eks.name
  node_role_arn  = var.node_role_arn
  subnet_ids     = var.private_subnets
  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }

  #ami_type        = "AL2_x86_64" # Use the appropriate AMI type for your instance type
  #release_version = "ami-0a0b0c0d0e0f0g0h0" # Replace with the actual AMI ID for Kubernetes version 1.25

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

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "server.global.scrape_interval"
    value = "15s"
  }

  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }

  timeout = 1200  # Increase timeout to 20 minutes

  # ✅ Enable JSON logging for better observability
  set {
    name  = "prometheus.prometheusSpec.logLevel"
    value = "info"
  }

  set {
    name  = "prometheus.prometheusSpec.logFormat"
    value = "json"
  }

  # ✅ Configure Prometheus to scrape logs from Kubernetes Pods
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  create_namespace = true

  # ✅ Set LoadBalancer for External Access
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  # ✅ Default Admin Credentials
  set {
    name  = "adminUser"
    value = "admin"
  }

  set {
    name  = "adminPassword"
    value = "admin123"
  }

  # ✅ Enable Dashboard Discovery
  set {
    name  = "grafana.sidecar.dashboards.enabled"
    value = "true"
  }

  set {
    name  = "grafana.sidecar.dashboards.searchNamespace"
    value = "ALL"
  }

  # ✅ Auto-connect Prometheus as a Data Source in Grafana
  set {
    name  = "grafana.datasources.datasources.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "grafana.datasources.datasources.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "grafana.datasources.datasources.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "grafana.datasources.datasources.yaml.datasources[0].url"
    value = "http://prometheus-kube-prometheus-prometheus.monitoring:9090"
  }

  set {
    name  = "grafana.datasources.datasources.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "grafana.datasources.datasources.yaml.datasources[0].isDefault"
    value = "true"
  }

  # ✅ Automatically Import Predefined Dashboards
  set {
    name  = "grafana.dashboardsProvider.enabled"
    value = "true"
  }

  set {
    name  = "grafana.dashboards.default.kubernetes.url"
    value = "https://grafana.com/api/dashboards/315/download"
  }

  set {
    name  = "grafana.dashboards.default.kubernetes.type"
    value = "json"
  }

  set {
    name  = "grafana.dashboards.default.node_exporter.url"
    value = "https://grafana.com/api/dashboards/1860/download"
  }

  set {
    name  = "grafana.dashboards.default.node_exporter.type"
    value = "json"
  }

  set {
    name  = "grafana.defaultDashboardsEnabled"
    value = "true"
  }

  # ✅ Ensure Dashboards are Auto-Synced
  set {
    name  = "grafana.sidecar.datasources.enabled"
    value = "true"
  }

  timeout = 1800
}
