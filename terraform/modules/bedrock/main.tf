# Skeleton: LLM enrichment with Amazon Bedrock Batch Inference.
# Note: enable model access for ${var.model_id} in the Bedrock console first.
# Resources to define:
#   - IAM batch inference role (see iam module) with S3 I/O access
#   - S3 input prefix (prompt JSONL) and output prefix (result JSONL) within the datalake bucket
#   - The batch job (CreateModelInvocationJob) is launched by Step Functions, not a static resource
