# Ingestion job image (AWS Batch on Fargate).
FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Install deps first for layer caching — only re-runs when pyproject.toml/uv.lock change.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# Copy source and install the package itself.
COPY README.md ./
COPY amazon_reviews_analyzer/ ./amazon_reviews_analyzer/
COPY config/ ./config/
RUN uv sync --frozen --no-dev

RUN useradd --system --no-create-home appuser
USER appuser

ENV PATH="/app/.venv/bin:$PATH"

ENTRYPOINT ["python", "-m", "amazon_reviews_analyzer.ingestion.download"]