# Skeleton: least-privilege IAM roles per service (see IAM table in docs/dev.md).
# Define one role per service with concrete ARNs (not wildcards) in production:
#   - <name_prefix>-batch-task-role        (S3 bronze/ prefix, CloudWatch logs, ECR pull)
#   - <name_prefix>-glue-job-role          (S3 silver/gold/scripts prefixes, Glue Catalog, KMS, logs)
#   - <name_prefix>-bedrock-batch-role     (S3 I/O prefixes, bedrock:*ModelInvocationJob, KMS)
#   - <name_prefix>-stepfunctions-role     (batch/glue/bedrock + scoped iam:PassRole)
#   - <name_prefix>-cicd-oidc-role         (GitHub Actions OIDC federation)
#
# Suggested pattern per role:
#   data "aws_iam_policy_document" "<role>_assume" { ... }
#   resource "aws_iam_role" "<role>" { assume_role_policy = ... }
#   data "aws_iam_policy_document" "<role>_perms" { statement { ... } }
#   resource "aws_iam_role_policy" "<role>" { ... }
