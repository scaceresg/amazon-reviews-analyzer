## --- Trust policy locals --- ##
locals {
  iam_batch_assume = [
    {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [local.account_id]
        }
      ]
    }
  ]

  iam_glue_assume = [
    {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["glue.amazonaws.com"]
      }
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [local.account_id]
        }
      ]
    }
  ]

  iam_bedrock_assume = [
    {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["bedrock.amazonaws.com"]
      }
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [local.account_id]
        }
      ]
    }
  ]

  iam_stepfunctions_assume = [
    {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["states.amazonaws.com"]
      }
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [local.account_id]
        }
      ]
    }
  ]

  ## --- Permission policy locals --- ##
  iam_batch_execution_stmts = [
    {
      sid     = "ECRPull"
      effect  = "Allow"
      actions = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"]
      resources = [
        "arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}-ingestion"
      ]
    },
    {
      sid       = "ECRToken"
      effect    = "Allow"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    },
    {
      sid     = "CloudWatchLogs"
      effect  = "Allow"
      actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
      resources = [
        "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/batch/*"
      ]
    },
  ]

  iam_batch_task_stmts = [
    {
      sid       = "S3BronzeObjects"
      effect    = "Allow"
      actions   = ["s3:PutObject", "s3:GetObject"]
      resources = ["${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/bronze/*"]
    },
    {
      sid       = "S3BronzeList"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn]
      conditions = [
        {
          test     = "StringLike"
          variable = "s3:prefix"
          values   = ["bronze/*"]
        }
      ]
    },
  ]

  iam_glue_job_stmts = [
    {
      sid       = "S3BronzeRead"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/bronze/*"]
    },
    {
      sid     = "S3SilverGoldWrite"
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [
        "${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/silver/*",
        "${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/gold/*",
      ]
    },
    {
      sid       = "S3ScriptsRead"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/scripts/*"]
    },
    {
      sid       = "S3List"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn]
      conditions = [
        {
          test     = "StringLike"
          variable = "s3:prefix"
          values   = ["bronze/*", "silver/*", "gold/*", "scripts/*"]
        }
      ]
    },
    {
      sid    = "GlueCatalog"
      effect = "Allow"
      actions = [
        "glue:GetDatabase",
        "glue:GetTable", "glue:GetTables",
        "glue:CreateTable", "glue:UpdateTable",
        "glue:GetPartition", "glue:GetPartitions",
        "glue:BatchCreatePartition", "glue:CreatePartition", "glue:UpdatePartition",
      ]
      resources = [
        "arn:${local.partition}:glue:${var.aws_region}:${local.account_id}:catalog",
        "arn:${local.partition}:glue:${var.aws_region}:${local.account_id}:database/${var.project_name}",
        "arn:${local.partition}:glue:${var.aws_region}:${local.account_id}:table/${var.project_name}/*",
      ]
    },
    {
      sid     = "CloudWatchLogs"
      effect  = "Allow"
      actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = [
        "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws-glue/*"
      ]
    },
  ]

  iam_bedrock_batch_stmts = [
    {
      sid       = "S3LLMInput"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/gold/llm/input/*"]
    },
    {
      sid       = "S3LLMOutput"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn}/gold/llm/output/*"]
    },
    {
      sid       = "S3LLMList"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [module.amazon_reviews_analyzer_datalake_s3_bucket.bucket_arn]
      conditions = [
        {
          test     = "StringLike"
          variable = "s3:prefix"
          values   = ["gold/llm/*"]
        }
      ]
    },
  ]

  iam_stepfunctions_stmts = [
    {
      sid     = "BatchSubmit"
      effect  = "Allow"
      actions = ["batch:SubmitJob", "batch:DescribeJobs", "batch:TerminateJob"]
      # batch:DescribeJobs and batch:TerminateJob don't support resource-level scoping
      resources = ["*"]
    },
    {
      sid    = "GlueJobs"
      effect = "Allow"
      actions = [
        "glue:StartJobRun",
        "glue:GetJobRun", "glue:GetJobRuns",
        "glue:BatchStopJobRun",
      ]
      resources = [
        "arn:${local.partition}:glue:${var.aws_region}:${local.account_id}:job/${var.project_name}-*"
      ]
    },
    {
      sid    = "BedrockBatch"
      effect = "Allow"
      actions = [
        "bedrock:CreateModelInvocationJob",
        "bedrock:GetModelInvocationJob",
        "bedrock:StopModelInvocationJob",
      ]
      # Foundation model ARNs use double-colon (no account ID) — AWS-managed resources
      resources = ["arn:${local.partition}:bedrock:${var.aws_region}::foundation-model/*"]
    },
    {
      sid     = "PassRole"
      effect  = "Allow"
      actions = ["iam:PassRole"]
      resources = [
        "arn:${local.partition}:iam::${local.account_id}:role/${var.project_name}-batch-task-*",
        "arn:${local.partition}:iam::${local.account_id}:role/${var.project_name}-glue-job-*",
        "arn:${local.partition}:iam::${local.account_id}:role/${var.project_name}-bedrock-batch-*",
      ]
    },
    {
      sid    = "SFNLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogDelivery",
        "logs:GetLogDelivery",
        "logs:UpdateLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:PutLogEvents",
        "logs:PutResourcePolicy",
        "logs:DescribeResourcePolicies",
        "logs:DescribeLogGroups",
      ]
      resources = ["*"]
    },
  ]
}

## --- IAM roles --- ##

module "amazon_reviews_analyzer_batch_execution_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-batch-execution"
  project_name  = var.project_name

  assume_role_statements = local.iam_batch_assume
  policy_statements      = local.iam_batch_execution_stmts
}

module "amazon_reviews_analyzer_batch_task_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-batch-task"
  project_name  = var.project_name

  assume_role_statements = local.iam_batch_assume
  policy_statements      = local.iam_batch_task_stmts
}

module "amazon_reviews_analyzer_glue_job_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-glue-job"
  project_name  = var.project_name

  assume_role_statements = local.iam_glue_assume
  policy_statements      = local.iam_glue_job_stmts
}

module "amazon_reviews_analyzer_bedrock_batch_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-bedrock-batch"
  project_name  = var.project_name

  assume_role_statements = local.iam_bedrock_assume
  policy_statements      = local.iam_bedrock_batch_stmts
}

module "amazon_reviews_analyzer_stepfunctions_iam_role" {
  source        = "./modules/iam"
  iam_role_name = "${var.project_name}-stepfunctions"
  project_name  = var.project_name

  assume_role_statements = local.iam_stepfunctions_assume
  policy_statements      = local.iam_stepfunctions_stmts
}
