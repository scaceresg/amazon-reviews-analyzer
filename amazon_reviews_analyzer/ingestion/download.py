"""Download reviews and metadata from HuggingFace and upload to the S3 bronze zone.

Designed to run as a container in AWS Batch (Fargate).

Local dry-run (no AWS credentials needed):
    DRY_RUN=true python -m amazon_reviews_analyzer.ingestion.download

Real run (requires AWS credentials and a live datalake bucket):
    python -m amazon_reviews_analyzer.ingestion.download
"""

from __future__ import annotations

import os
import sys

from huggingface_hub import list_repo_files

from amazon_reviews_analyzer.utils.config import load_config
from amazon_reviews_analyzer.utils.logging import get_logger

logger = get_logger(__name__)

HF_DATASET = "McAuley-Lab/Amazon-Reviews-2023"
HF_REPO_TYPE = "dataset"


def list_category_files(category: str) -> list[str]:
    """Return HuggingFace paths for the raw review and metadata files of a category."""
    prefixes = (f"raw_review_{category}", f"raw_meta_{category}")
    return [
        f
        for f in list_repo_files(HF_DATASET, repo_type=HF_REPO_TYPE)
        if f.startswith(prefixes)
    ]


def upload_to_s3(local_path: str, bucket: str, s3_key: str) -> None:
    """Upload a local file to S3."""
    import boto3

    s3 = boto3.client("s3")
    logger.info("Uploading %s → s3://%s/%s", local_path, bucket, s3_key)
    s3.upload_file(local_path, bucket, s3_key)


def download_category(
    category: str,
    datalake_bucket: str,
    bronze_prefix: str,
    dry_run: bool = False,
) -> None:
    """Download a category's files from HuggingFace and upload to S3 bronze/.

    Args:
        category: Category name (e.g. ``All_Beauty``).
        datalake_bucket: S3 datalake bucket name.
        bronze_prefix: Prefix for the bronze zone (e.g. ``bronze/``).
        dry_run: When True, log actions without downloading or uploading anything.
    """
    logger.info("Resolving files for category '%s' in %s", category, HF_DATASET)
    files = list_category_files(category)

    if not files:
        logger.warning("No files found for category '%s' — skipping", category)
        return

    for hf_path in files:
        s3_key = f"{bronze_prefix}category={category}/{os.path.basename(hf_path)}"
        dest = f"s3://{datalake_bucket}/{s3_key}"

        if dry_run:
            logger.info(
                "[DRY RUN] Would download hf://%s/%s → %s", HF_DATASET, hf_path, dest
            )
            continue

        # TODO: stream directly to S3 without writing to disk using snapshot_download
        # or hf_hub_download + upload_to_s3 in a temp dir.
        logger.info("Downloading hf://%s/%s", HF_DATASET, hf_path)
        raise NotImplementedError(
            "Real download not yet implemented — use DRY_RUN=true locally"
        )


def main() -> None:
    """Entry point for the ingestion job."""
    config = load_config()
    dry_run = os.getenv("DRY_RUN", "").lower() in ("1", "true", "yes")

    if dry_run:
        logger.info("=== DRY RUN mode — no files will be downloaded or uploaded ===")

    datalake_bucket = config["datalake_bucket"]
    bronze_prefix = config.get("bronze_prefix", "bronze/")
    categories: list[str] = config.get("categories", [])

    if not categories:
        logger.error(
            "No categories configured. Check 'categories' in your config YAML."
        )
        sys.exit(1)

    logger.info(
        "Starting ingestion: %d categor%s → s3://%s/%s",
        len(categories),
        "y" if len(categories) == 1 else "ies",
        datalake_bucket,
        bronze_prefix,
    )

    failed: list[str] = []
    for category in categories:
        try:
            download_category(category, datalake_bucket, bronze_prefix, dry_run=dry_run)
        except Exception:
            logger.exception("Failed to process category '%s'", category)
            failed.append(category)

    if failed:
        logger.error("Ingestion completed with %d failure(s): %s", len(failed), failed)
        sys.exit(1)

    logger.info("Ingestion complete.")


if __name__ == "__main__":
    main()
