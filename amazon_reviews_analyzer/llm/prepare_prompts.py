"""Build the JSONL input file for Bedrock Batch Inference.

Stub. The real implementation reads reviews from the silver prefix and
produces a JSONL file with one record per review (recordId + prompt) in
the format expected by ``CreateModelInvocationJob``.
"""

from __future__ import annotations

CLASSIFICATION_INSTRUCTION = (
    "Classify the review by sentiment (positive/neutral/negative), extract the "
    "mentioned aspects, and identify the main topics. Respond in JSON."
)


def build_batch_input(silver_prefix: str, output_uri: str) -> None:
    """Generate the prompt JSONL file for the batch job.

    Args:
        silver_prefix: S3 prefix containing the silver-layer reviews.
        output_uri: S3 destination for the batch input JSONL file.
    """
    # TODO: read reviews and serialise prompts -> output_uri
    raise NotImplementedError
