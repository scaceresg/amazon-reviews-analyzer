resource "aws_s3_bucket" "bucket" {
    bucket = "${lower(var.bucket_name)}-${terraform.workspace}"
    region = var.aws_region
    bucket_namespace = var.bucket_namespace

    force_destroy = var.force_destroy
    object_lock_enabled = var.object_lock_enabled

    tags = {
        Project = var.project_name
        Environment = terraform.workspace
        ManagedBy = "terraform"
    }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
    bucket = aws_s3_bucket.bucket.id
    region = var.aws_region
    versioning_configuration {
        status = var.versioning_status
    }
}

resource "aws_s3_bucket_abac" "bucket_abac" {
    bucket = aws_s3_bucket.bucket.id
    region = var.aws_region
    abac_status {
        status = var.abac_status
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_config" {
    count  = length(var.lifecycle_rules) > 0 ? 1 : 0
    bucket = aws_s3_bucket.bucket.id
    region = var.aws_region

    dynamic "rule" {
        for_each = var.lifecycle_rules
        content {
            id     = rule.value.id
            status = rule.value.status

            dynamic "filter" {
                for_each = rule.value.filter != null ? [rule.value.filter] : []
                content {
                    prefix                   = filter.value.prefix
                    object_size_greater_than = filter.value.object_size_greater_than
                    object_size_less_than    = filter.value.object_size_less_than

                    dynamic "tag" {
                        for_each = filter.value.tag != null ? [filter.value.tag] : []
                        content {
                            key   = tag.value.key
                            value = tag.value.value
                        }
                    }

                    dynamic "and" {
                        for_each = filter.value.and != null ? [filter.value.and] : []
                        content {
                            prefix                   = and.value.prefix
                            object_size_greater_than = and.value.object_size_greater_than
                            object_size_less_than    = and.value.object_size_less_than
                            tags                     = and.value.tags
                        }
                    }
                }
            }

            dynamic "expiration" {
                for_each = rule.value.expiration != null ? [rule.value.expiration] : []
                content {
                    date                         = expiration.value.date
                    days                         = expiration.value.days
                    expired_object_delete_marker = expiration.value.expired_object_delete_marker
                }
            }

            dynamic "transition" {
                for_each = rule.value.transition
                content {
                    date          = transition.value.date
                    days          = transition.value.days
                    storage_class = transition.value.storage_class
                }
            }

            dynamic "noncurrent_version_expiration" {
                for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
                content {
                    newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
                    noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
                }
            }

            dynamic "noncurrent_version_transition" {
                for_each = rule.value.noncurrent_version_transition
                content {
                    newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
                    noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
                    storage_class             = noncurrent_version_transition.value.storage_class
                }
            }

            dynamic "abort_incomplete_multipart_upload" {
                for_each = rule.value.abort_incomplete_multipart_upload != null ? [rule.value.abort_incomplete_multipart_upload] : []
                content {
                    days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
                }
            }
        }
    }
}

resource "aws_kms_key" "bucket_kms_key" {
    count = var.sse_algorithm == "aws:kms" ? 1 : 0
    description = "KMS key for ${aws_s3_bucket.bucket.id} bucket"
    deletion_window_in_days = 7
    enable_key_rotation = true
    tags = {
        ProjectName = var.project_name
        Environment = terraform.workspace
        ManagedBy = "terraform"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_server_side_encryption" {
    bucket = aws_s3_bucket.bucket.id
    region = var.aws_region
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = var.sse_algorithm
            kms_master_key_id = var.sse_algorithm == "aws:kms" ? aws_kms_key.bucket_kms_key[0].arn : null
        }
        blocked_encryption_types = var.blocked_encryption_types
        bucket_key_enabled = var.bucket_key_enabled
    }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
    bucket = aws_s3_bucket.bucket.id
    region = var.aws_region
    block_public_acls = var.block_public_acls
    block_public_policy = var.block_public_policy
    ignore_public_acls = var.ignore_public_acls
    restrict_public_buckets = var.restrict_public_buckets
}