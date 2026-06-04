terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 native locking (use_lockfile = true) — no DynamoDB table required.
  # The tfstate bucket is created manually from the AWS console UI and passed
  # at init time:
  #   terraform init -backend-config="bucket=<bucket-name>"
  backend "s3" {
    key          = "amazon-reviews-analyzer/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
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
