output "batch_compute_environment_arn" {
  description = "ARN of the batch compute environment"
  value       = aws_batch_compute_environment.batch_compute_environment.arn
}

output "batch_compute_environment_ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_batch_compute_environment.batch_compute_environment.ecs_cluster_arn
}

output "batch_compute_environment_status" {
  description = "Status of the batch compute environment"
  value       = aws_batch_compute_environment.batch_compute_environment.status
}

output "batch_job_queue_arn" {
  description = "ARN of the batch job queue"
  value       = aws_batch_job_queue.batch_job_queue.arn
}