output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.ecr_repository.arn
}

output "ecr_repository_registry_id" {
  description = "Registry ID of the ECR repository"
  value       = aws_ecr_repository.ecr_repository.registry_id
}

output "ecr_repository_repository_url" {
  description = "Repository URL of the ECR repository"
  value       = aws_ecr_repository.ecr_repository.repository_url
}