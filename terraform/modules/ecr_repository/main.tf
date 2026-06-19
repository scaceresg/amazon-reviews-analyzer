resource "aws_ecr_repository" "ecr_repository" {
  name                 = "${var.repository_name}-repository"
  region               = var.aws_region
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  dynamic "encryption_configuration" {
    for_each = var.encryption_configuration != null ? [var.encryption_configuration] : []
    content {
      encryption_type = encryption_configuration.value.encryption_type
      kms_key         = encryption_configuration.value.kms_key
    }
  }

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = (
      length(coalesce(var.image_tag_mutability_exclusion_filters, [])) > 0 &&
      contains(["IMMUTABLE_WITH_EXCLUSION", "MUTABLE_WITH_EXCLUSION"], var.image_tag_mutability)
    ) ? var.image_tag_mutability_exclusion_filters : []
    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }

  tags = {
    ProjectName = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_key" "ecr_repository_kms_key" {
  count                   = var.encryption_configuration != null && var.encryption_configuration.encryption_type == "KMS" ? 1 : 0
  description             = "KMS key for ${aws_ecr_repository.ecr_repository.id} repository"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation
  tags = {
    ProjectName = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}