resource "aws_kms_key" "lake" {
  description             = "${var.name_prefix} data lake encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Primary datalake bucket. Medallion zones are S3 prefixes, not separate buckets:
#   bronze/   -> raw HuggingFace jsonl.gz files
#   silver/   -> clean, typed Parquet
#   gold/     -> aggregates + LLM enrichment
#   scripts/  -> Glue job scripts and LLM artefacts
resource "aws_s3_bucket" "datalake" {
  bucket = "${var.name_prefix}-datalake"
}

# Separate bucket for Athena query results (distinct lifecycle and access policy).
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.name_prefix}-athena-results"
}

resource "aws_s3_bucket_versioning" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.lake.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.lake.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket                  = aws_s3_bucket.datalake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle for the bronze/ prefix: transition to cheaper storage, then expire.
resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    id     = "bronze-transition"
    status = "Enabled"
    filter { prefix = "bronze/" }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 180
    }
  }
}

# Lifecycle for Athena results: expire query output after 30 days.
resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    id     = "athena-results-expiry"
    status = "Enabled"
    expiration { days = 30 }
  }
}
