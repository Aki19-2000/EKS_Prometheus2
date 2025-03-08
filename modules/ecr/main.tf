resource "aws_ecr_repository" "patient_service" {
  name = "patient-service"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "patient-service"
  }
}

resource "aws_ecr_repository" "appointment_service" {
  name = "appointment-service"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "appointment-service"
  }
}