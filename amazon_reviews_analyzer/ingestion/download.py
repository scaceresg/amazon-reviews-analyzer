"""Download reviews and metadata from HuggingFace and upload to the S3 bronze zone.

Designed to run as a container in AWS Batch (Fargate). Stub: the real
implementation uses ``huggingface_hub`` to download the ``.jsonl.gz`` files
per category and ``boto3`` to upload them to the ``bronze/`` prefix of the
datalake bucket.
"""

from __future__ import annotations

from amazon_reviews_analyzer.utils.config import load_config
from amazon_reviews_analyzer.utils.logging import get_logger

logger = get_logger(__name__)

HF_DATASET = "McAuley-Lab/Amazon-Reviews-2023"


def download_category(category: str, datalake_bucket: str, bronze_prefix: str) -> None:
    """Download a category's files and upload them to S3 bronze/.

    Args:
        category: Category name (e.g. ``All_Beauty``).
        datalake_bucket: S3 datalake bucket name.
        bronze_prefix: Prefix for the bronze zone within the bucket (e.g. ``bronze/``).
    """
    # TODO: download raw_review_<category> and raw_meta_<category> via huggingface_hub
    # TODO: upload to s3://{datalake_bucket}/{bronze_prefix}category={category}/...
    logger.info("Downloading category %s from %s", category, HF_DATASET)
    raise NotImplementedError


def main() -> None:
    """Entry point for the ingestion job."""
    config = load_config()
    datalake_bucket = config["datalake_bucket"]
    bronze_prefix = config.get("bronze_prefix", "bronze/")
    for category in config.get("categories", []):
        download_category(category, datalake_bucket, bronze_prefix)


if __name__ == "__main__":
    main()
