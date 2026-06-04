# Skeleton: Glue Data Catalog and ETL jobs.
# Resources to define:
#   - aws_glue_catalog_database.reviews
#   - aws_glue_job.silver        (script: scripts/etl/silver_job.py in datalake bucket)
#   - aws_glue_job.gold_merge    (script: scripts/etl/gold_merge_job.py in datalake bucket)
#   - aws_glue_catalog_table.*   (explicit table definitions; dataset schema is stable)
#   - (optional) aws_glue_crawler.* for initial discovery or schema drift detection
