# ------------------------------
# EKS Cluster Outputs
# ------------------------------
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.eks.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}


output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.eks.arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_ca_cert" {
  description = "EKS cluster certificate authority"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}


# ------------------------------
# Node Group Outputs
# ------------------------------
output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.eks_nodes.id
}

output "eks_node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.eks_nodes.arn
}

output "eks_node_group_status" {
  description = "Current status of the EKS node group"
  value       = aws_eks_node_group.eks_nodes.status
}
