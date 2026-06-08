## --- IAM roles --- ##

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

module "amazon_reviews_analyzer_batch_execution_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-batch-execution"
  project_name  = var.project_name
  assume_role_statements = [
    {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
      condition = {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [local.account_id]
      }
    }
  ]
  policy_statements = [
    {
      sid     = "ECRPull"
      actions = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"]
      effect  = "Allow"
      resources = [
        "arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}-ingestion"
      ]
    },
    {
      sid       = "ECRToken"
      actions   = ["ecr:GetAuthorizationToken"]
      effect    = "Allow"
      resources = ["*"]
    }
  ]
}

module "amazon_reviews_analyzer_batch_task_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-batch-task"
  project_name  = var.project_name
  assume_role_statements = [
    {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
      condition = {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [local.account_id]
      }
    }
  ]
  policy_statements = [
    {
      sid     = "S3BronzeReadWrite"
      actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      effect  = "Allow"
      resources = [
        module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn,
        "${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/bronze/*"
      ]
    },
    {
      sid     = "CloudWatchLogs"
      actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
      effect  = "Allow"
      resources = [
        "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/batch/*"
      ]
    }
  ]
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

## --- Batch Ingestion Job --- ##
module "amazon_reviews_analyzer_batch_ingestion_job" {
  source                   = "./modules/batch"
  project_name             = var.project_name
  aws_region               = var.aws_region
  batch_job_name           = var.project_name
  compute_environment_type = "MANAGED"
  compute_resources = {
    type               = "FARGATE"
    max_vcpus          = 256
    security_group_ids = var.security_group_ids
    subnets            = var.subnet_ids
  }
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
