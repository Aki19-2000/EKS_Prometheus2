module "vpc" {
  source         = "../modules/vpc"
  vpc_name       = var.vpc_name
  vpc_cidr       = var.vpc_cidr
  azs            = var.azs
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

module "iam" {
  source = "../modules/iam"
}

#module "ecr" {
 # source = "../modules/ecr"
#}

module "eks-cluster" {
  source                 = "../modules/eks-cluster"
  cluster_name           = var.cluster_name
  cluster_version        = var.cluster_version
  subnets                = module.vpc.private_subnets
  vpc_id                 = module.vpc.vpc_id
  cluster_role_arn       = module.iam.eks_cluster_role_arn
  node_role_arn          = module.iam.eks_node_role_arn
  desired_capacity       = var.desired_capacity
  max_capacity           = var.max_capacity
  min_capacity           = var.min_capacity
  instance_type          = var.instance_type
  patient_image          = var.patient_image
  appointment_image      = var.appointment_image
  grafana_admin_password = var.grafana_admin_password
}
