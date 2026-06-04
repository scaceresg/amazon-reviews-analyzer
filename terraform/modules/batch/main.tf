# Skeleton: ingestion layer with AWS Batch on Fargate.
# Resources to define:
#   - aws_ecr_repository.ingestion              (Docker image for the HF download job)
#   - aws_batch_compute_environment.fargate     (FARGATE or FARGATE_SPOT)
#   - aws_batch_job_queue.ingestion
#   - aws_batch_job_definition.ingestion        (container = ECR image; env: CATEGORIES, DATALAKE_BUCKET)
