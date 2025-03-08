variable "cluster_name" {
  description = "The name of the EKS cluster"
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
}

variable "subnets" {
  description = "The subnets for the EKS cluster"
  type        = list(string)
}

variable "private_subnets" {
  description = "The private subnets for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID for the EKS cluster"
}

variable "cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster"
}

variable "node_role_arn" {
  description = "The ARN of the IAM role for the EKS nodes"
}

variable "desired_capacity" {
  description = "The desired number of worker nodes"
  default     = 2
}

variable "max_capacity" {
  description = "The maximum number of worker nodes"
  default     = 3
}

variable "min_capacity" {
  description = "The minimum number of worker nodes"
  default     = 1
}

variable "instance_type" {
  description = "The instance type for the worker nodes"
  default     = "t3.medium"
}

variable "patient_image" {
  description = "The Docker image for the Patient Service"
}

variable "appointment_image" {
  description = "The Docker image for the Appointment Service"
}

variable "grafana_admin_password" {
  description = "The admin password for Grafana"
  default     = "your-grafana-admin-password"
}

variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-west-2"
}
