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

# locals {
#   name_prefix = "${var.project}-${terraform.workspace}"
# }

# # S3 data lake (datalake bucket with medallion prefixes + athena-results) and KMS key.
# module "amazon_reviews_analyzer_s3_lake" {
#   source      = "./modules/s3_lake"
#   name_prefix = local.name_prefix
# }

# # IAM roles and least-privilege policies per service.
# module "iam" {
#   source      = "./modules/iam"
#   name_prefix = local.name_prefix
# }

# # Ingestion: ECR repository + AWS Batch on Fargate.
# module "batch" {
#   source      = "./modules/batch"
#   name_prefix = local.name_prefix
# }

# # Glue Data Catalog database + PySpark jobs (silver, gold-merge).
# module "glue" {
#   source      = "./modules/glue"
#   name_prefix = local.name_prefix
# }

# # Bedrock batch inference: IAM role + I/O S3 prefixes.
# module "bedrock" {
#   source      = "./modules/bedrock"
#   name_prefix = local.name_prefix
#   model_id    = var.bedrock_model_id
# }

# # Orchestration: Step Functions state machine + EventBridge schedule.
# module "step_functions" {
#   source      = "./modules/step_functions"
#   name_prefix = local.name_prefix
# }

# # Query layer: Athena workgroup.
# module "athena" {
#   source      = "./modules/athena"
#   name_prefix = local.name_prefix
# }

# # Visualisation: QuickSight.
# module "quicksight" {
#   source      = "./modules/quicksight"
#   name_prefix = local.name_prefix
# }

# # Observability: CloudWatch log groups and alarms.
# module "observability" {
#   source      = "./modules/observability"
#   name_prefix = local.name_prefix
# }
