
resource "aws_ecr_repository" "application" {
  name                 = "sample-application"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project     = "devops-portfolio"
    ManagedBy   = "Terraform"
    Environment = "portfolio"
  }
}

output "ecr_repository_url" {
  description = "URL used to push and pull application images"
  value       = aws_ecr_repository.application.repository_url
}
