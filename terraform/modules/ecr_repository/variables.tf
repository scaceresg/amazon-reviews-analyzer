variable "aws_region" {
  description = "AWS region where the batch job is deployed"
  type        = string
}

variable "encryption_configuration" {
  description = <<EOF
    The encryption configuration for the repository.
    It includes the encryption type and the KMS key ARN.
    The encryption type can be 'AES256' or 'KMS'.
    For example:
    encryption_configuration = {
      encryption_type = "KMS"
      kms_key = "arn:aws:kms:<region>:<account-id>:key/<key-id>"
    }
    EOF
  type = object({
    encryption_type = string
    kms_key         = string
  })
  default = null
}

variable "force_delete" {
  description = "If true, the repository will be deleted even if it contains images"
  type        = bool
  default     = false
}

variable "image_tag_mutability" {
  description = <<EOF
    The image tag mutability setting for the repository. It can be 'MUTABLE', 'IMMUTABLE', 
    'IMMUTABLE_WITH_EXCLUSION' or 'MUTABLE_WITH_EXCLUSION'.
    Defaults to 'MUTABLE'.
    EOF
  type        = string
  default     = "MUTABLE"
}

variable "image_tag_mutability_exclusion_filters" {
  description = <<EOF
    Exclusion filters for image tag mutability. Only applied when image_tag_mutability is
    IMMUTABLE_WITH_EXCLUSION or MUTABLE_WITH_EXCLUSION.
    For example:
    image_tag_mutability_exclusion_filters = [
      { filter = "latest", filter_type = "WILDCARD" }
    ]
    EOF
  type = list(object({
    filter      = string
    filter_type = string
  }))
  default = []
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

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "repository_name" {
  description = "Name of the repository"
  type        = string
}