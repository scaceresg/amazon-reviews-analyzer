"""Glue job (PySpark): merge silver + LLM enrichment -> gold.

Stub. The real implementation:
  - joins reviews + metadata (on parent_asin) from the silver prefix
  - integrates Bedrock batch results (sentiment, aspects, topics)
  - writes aggregated tables for the dashboard to the gold prefix
  - updates the Glue Data Catalog
"""

from __future__ import annotations


def run() -> None:
    """Run the silver + enrichment -> gold merge."""
    # TODO: implement with awsglue + pyspark
    raise NotImplementedError


if __name__ == "__main__":
    run()
