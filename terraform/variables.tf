variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resource names."
  type        = string
  default     = "amazon-reviews-analyzer"
}

variable "subnet_ids" {
  description = "Subnet IDs for the batch job"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the batch job"
  type        = list(string)
}
