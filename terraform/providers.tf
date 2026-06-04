terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Use terraform init -backend-config="bucket=<bucket-name>"
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
