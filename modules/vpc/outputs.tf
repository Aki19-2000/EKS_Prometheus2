output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnets" {
  description = "The public subnets"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnets" {
  description = "The private subnets"
  value       = aws_subnet.private_subnet[*].id
}