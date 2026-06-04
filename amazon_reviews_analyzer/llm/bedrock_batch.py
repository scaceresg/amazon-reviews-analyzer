"""Submit and track a Bedrock Batch Inference job.

Stub. The real implementation uses ``boto3`` (bedrock client) to create the
job via ``create_model_invocation_job`` and poll its status.
"""

from __future__ import annotations

from amazon_reviews_analyzer.utils.logging import get_logger

logger = get_logger(__name__)


def submit_batch_job(
    model_id: str,
    input_uri: str,
    output_uri: str,
    role_arn: str,
) -> str:
    """Create a Bedrock batch inference job and return its identifier.

    Args:
        model_id: Bedrock model to use (e.g. ``amazon.nova-lite-v1:0``).
        input_uri: S3 URI of the JSONL input file.
        output_uri: S3 URI where results will be written.
        role_arn: IAM role ARN assumed by Bedrock to read/write S3.

    Returns:
        ARN or identifier of the created job.
    """
    # TODO: boto3.client("bedrock").create_model_invocation_job(...)
    logger.info("Submitting Bedrock batch job with model %s", model_id)
    raise NotImplementedError
