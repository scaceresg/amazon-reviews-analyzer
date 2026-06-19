variable "abac_status" {
  description = "ABAC status of the bucket. It can be 'Enabled' or 'Disabled'"
  type        = string
  default     = "Disabled"
}

variable "aws_region" {
  description = "AWS region where the bucket is deployed"
  type        = string
}

variable "blocked_encryption_types" {
  description = "Blocked encryption types of the bucket. It can be 'SSE-C'"
  type        = list(string)
  default     = ["SSE-C"]
}

variable "block_public_acls" {
  description = "If true, public ACLs will be blocked on the bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "If true, public policy will be blocked on the bucket"
  type        = bool
  default     = true
}

variable "bucket_key_enabled" {
  description = "If true, bucket key will be enabled on the bucket"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Name of the bucket"
  type        = string
}

variable "bucket_namespace" {
  description = "Defines the bucket naming scope. It can be 'global' or 'account-regional'"
  type        = string
  default     = "global"
}

variable "force_destroy" {
  description = "If true, the bucket will be destroyed even if it contains objects"
  type        = bool
  default     = false
}

variable "ignore_public_acls" {
  description = "If true, public ACLs will be ignored on the bucket"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_in_days" {
  description = "The number of days to wait before deleting the KMS key"
  type        = number
  default     = 7
}

variable "kms_key_enable_key_rotation" {
  description = "If true, the KMS key will be enabled for key rotation"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = <<EOF
    List of lifecycle rules for the bucket. Supports expiration, transitions, noncurrent version management,
    and multipart upload cleanup.
    For filter tags: use tags = [{ key, value }] for a single tag, or multiple entries (rendered via and.tags).
    For multiple tags with other predicates (prefix, object size), use filter.and explicitly.
    For example:
    lifecycle_rules = [
        {
        id     = "bronze-transition"
        filter = { prefix = "bronze/", tags = [{ key = "env", value = "prod" }] }
        transition = [
            { days = 30, storage_class = "STANDARD_IA" },
            { days = 90, storage_class = "GLACIER" }
        ]
        expiration = { days = 180 }
        },
        {
        id     = "cleanup-multipart"
        abort_incomplete_multipart_upload = { days_after_initiation = 7 }
        }
    ]
    EOF
  type = list(object({
    id     = string
    status = optional(string, "Enabled")

    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags = optional(list(object({
        key   = string
        value = string
      })))
      and = optional(object({
        prefix                   = optional(string)
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        tags                     = optional(map(string))
      }))
    }))

    expiration = optional(object({
      date                         = optional(string)
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))

    transition = optional(list(object({
      date          = optional(string)
      days          = optional(number)
      storage_class = string
    })), [])

    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = optional(number)
    }))

    noncurrent_version_transition = optional(list(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = optional(number)
      storage_class             = string
    })), [])

    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
  }))
  default = []

}

variable "object_lock_enabled" {
  description = "If true, object lock configuration will be enabled on the bucket"
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "restrict_public_buckets" {
  description = "If true, public buckets will be restricted on the bucket"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm of the bucket. It can be 'AES256', 'aws:kms' or 'aws:kms:dsse'"
  type        = string
  default     = "AES256"
}

variable "versioning_status" {
  description = "Versioning status of the bucket. It can be 'Enabled', 'Suspended' or 'Disabled'"
  type        = string
  default     = "Disabled"
}
