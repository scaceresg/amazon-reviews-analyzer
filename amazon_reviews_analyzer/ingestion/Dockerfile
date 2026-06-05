# Ingestion job image (AWS Batch on Fargate).
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Minimal runtime dependencies for the ingestion job.
RUN pip install --no-cache-dir "huggingface_hub>=0.23" "boto3>=1.34" "pyyaml>=6.0"

COPY amazon_reviews_analyzer/ /app/amazon_reviews_analyzer/
COPY config/ /app/config/

RUN useradd --system --no-create-home appuser
USER appuser

ENTRYPOINT ["python", "-m", "amazon_reviews_analyzer.ingestion.download"]
