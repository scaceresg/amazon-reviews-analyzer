output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.iam_role.arn
}

output "iam_role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.iam_role.id
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.iam_role.name
}

output "iam_role_unique_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.iam_role.unique_id
}