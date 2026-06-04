output "datalake_bucket" {
  description = "Name of the primary datalake bucket (medallion zones as prefixes)."
  value       = aws_s3_bucket.datalake.id
}

output "athena_results_bucket" {
  description = "Name of the Athena query results bucket."
  value       = aws_s3_bucket.athena_results.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the data lake."
  value       = aws_kms_key.lake.arn
}
