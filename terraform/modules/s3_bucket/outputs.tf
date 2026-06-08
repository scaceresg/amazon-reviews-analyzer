output "bucket_arn" {
    description = "ARN of the bucket"
    value = aws_s3_bucket.bucket.arn
}

output "bucket_domain_name" {
    description = "Domain name of the bucket"
    value = aws_s3_bucket.bucket.bucket_domain_name
}

output "bucket_id" {
    description = "ID of the bucket"
    value = aws_s3_bucket.bucket.id
}

output "bucket_region" {
    description = "Region of the bucket"
    value = aws_s3_bucket.bucket.region
}
