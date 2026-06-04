"""Glue job (PySpark): bronze (jsonl.gz) -> silver (partitioned Parquet).

Stub. The real implementation:
  - reads review and metadata jsonl files from the bronze prefix
  - normalises and types columns, deduplicates, and cleans the data
  - writes partitioned Parquet (by category) to the silver prefix
  - registers/updates the table in the Glue Data Catalog
"""

from __future__ import annotations


def run() -> None:
    """Run the bronze -> silver transformation."""
    # TODO: implement with awsglue + pyspark
    raise NotImplementedError


if __name__ == "__main__":
    run()
