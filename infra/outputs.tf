output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The private subnets"
  value       = module.vpc.private_subnets
}

output "eks_cluster_role_arn" {
  description = "The ARN of the EKS cluster role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "The ARN of the EKS node role"
  value       = module.iam.eks_node_role_arn
}

output "patient_service_repository_url" {
  description = "The URL of the patient service repository"
  value       = module.ecr.patient_service_repository_url
}

output "appointment_service_repository_url" {
  description = "The URL of the appointment service repository"
  value       = module.ecr.appointment_service_repository_url
}