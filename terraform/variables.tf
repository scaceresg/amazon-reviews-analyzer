variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name prefix applied to all resource names."
  type        = string
  default     = "amazon-reviews-analyzer"
}

variable "categories" {
  description = "Amazon Reviews'23 categories to ingest (MVP: a few small ones)."
  type        = list(string)
  default     = ["All_Beauty", "Gift_Cards", "Magazine_Subscriptions"]
}

variable "bedrock_model_id" {
  description = "Bedrock model used for batch inference (low-cost)."
  type        = string
  default     = "amazon.nova-lite-v1:0"
}
