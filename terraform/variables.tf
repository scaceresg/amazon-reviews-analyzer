variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

# variable "bedrock_model_id" {
#   description = "Bedrock model used for batch inference (low-cost)."
#   type        = string
#   default     = "amazon.nova-lite-v1:0"
# }

# variable "categories" {
#   description = "Amazon Reviews'23 categories to ingest (MVP: a few small ones)."
#   type        = list(string)
#   default     = ["All_Beauty", "Gift_Cards", "Magazine_Subscriptions"]
# }

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