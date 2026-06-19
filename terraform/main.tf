data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

## --- S3 buckets --- ##
module "amazon_reviews_analyzer_datalake_s3_bucket" {
  source            = "./modules/s3_bucket"
  bucket_name       = "${var.project_name}-datalake"
  aws_region        = var.aws_region
  project_name      = var.project_name
  versioning_status = "Enabled"
}

module "amazon_reviews_analyzer_athena_results_s3_bucket" {
  source            = "./modules/s3_bucket"
  bucket_name       = "${var.project_name}-athena-results"
  aws_region        = var.aws_region
  project_name      = var.project_name
  versioning_status = "Enabled"
  lifecycle_rules = [
    {
      id     = "athena-results-expiry"
      status = "Enabled"
      expiration = {
        days = 30
      }
    }
  ]
}

## --- ECR Repository --- ##
module "amazon_reviews_analyzer_ingestion_job_ecr_repository" {
  source               = "./modules/ecr_repository"
  repository_name      = "${var.project_name}-ingestion-job"
  project_name         = var.project_name
  aws_region           = var.aws_region
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
}

## --- Batch Ingestion Job --- ##
module "amazon_reviews_analyzer_batch_ingestion_job" {
  source                   = "./modules/batch_job"
  batch_job_name           = "${var.project_name}-ingestion"
  project_name             = var.project_name
  aws_region               = var.aws_region
  compute_environment_type = "MANAGED"
  compute_resources = {
    type               = "FARGATE"
    max_vcpus          = 256
    security_group_ids = var.security_group_ids
    subnets            = var.subnet_ids
  }
}
