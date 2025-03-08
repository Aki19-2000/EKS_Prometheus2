output "patient_service_repository_url" {
  description = "The URL of the patient service repository"
  value       = aws_ecr_repository.patient_service.repository_url
}

output "appointment_service_repository_url" {
  description = "The URL of the appointment service repository"
  value       = aws_ecr_repository.appointment_service.repository_url
}