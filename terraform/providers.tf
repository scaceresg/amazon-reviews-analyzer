terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 native locking (use_lockfile = true) — no DynamoDB table required.
  # The tfstate bucket is shared across projects and created manually from the
  # AWS console UI. Pass it at init time:
  #   terraform init -backend-config="bucket=<bucket-name>"
  #
  # State layout inside the bucket:
  #   amazon-reviews-analyzer/dev/terraform.tfstate   (workspace dev)
  #   amazon-reviews-analyzer/prod/terraform.tfstate  (workspace prod)
  backend "s3" {
    key                  = "terraform.tfstate"
    workspace_key_prefix = "amazon-reviews-analyzer"
    region               = "us-east-1"
    encrypt              = true
    use_lockfile         = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "amazon-reviews-analyzer"
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}
