# Amazon Reviews Analyzer — Agent Context

This file is the primary context document for AI agents (Cursor, Claude Code, etc.)
working in this repository. Read it before making any changes.

## Project overview

Serverless analytics platform built on AWS for the
[Amazon Reviews'23 dataset](https://amazon-reviews-2023.github.io/) (McAuley Lab,
HuggingFace: `McAuley-Lab/Amazon-Reviews-2023`).

**Current status:**

- **Implemented:** `utils/` (config loader + logging), `ingestion/download.py` (HF file listing, S3 upload helper, dry-run entry point); Terraform modules `s3_bucket` (datalake + athena-results buckets) and `batch` (Fargate compute environment + job queue) — both wired in `main.tf`.
- **Stubs (`raise NotImplementedError`):** `ingestion/download_category()` real-download path; all functions in `etl/` and `llm/`.
- **Skeleton modules (comment-only, not yet in `main.tf`):** `iam`, `glue`, `bedrock`, `step_functions`, `athena`, `quicksight`, `observability`.

## Architecture (ELT serverless, S3 medallion)

```
HuggingFace (.jsonl.gz)
    └─> AWS Batch (Fargate)          # downloads per category -> bronze/
         └─> Glue PySpark (silver job) # normalise + Parquet -> silver/
              └─> Bedrock Batch Inference  # sentiment/aspects/topics -> gold/llm/
                   └─> Glue PySpark (gold job) # merge silver + LLM -> gold/
                        └─> Athena (SQL) -> QuickSight (SPICE dashboards)
```

Orchestrated by **AWS Step Functions** triggered by **Amazon EventBridge Scheduler**.

### S3 layout (2 buckets per environment)

| Bucket | Purpose |
| --- | --- |
| `<prefix>-datalake` | Medallion zones as prefixes: `bronze/`, `silver/`, `gold/`, `scripts/` |
| `<prefix>-athena-results` | Athena query output (expires after 30 days) |

`<prefix>` = `amazon-reviews-analyzer-<workspace>` (e.g. `amazon-reviews-analyzer-dev`)

## Key design decisions

- **No separate bucket per medallion zone.** Zones are S3 prefixes within one datalake
  bucket. A second bucket for Athena results is needed because it has a different
  lifecycle and access policy.
- **Glue Crawler is optional.** The Amazon Reviews'23 schema is stable and documented.
  Tables are defined explicitly (`aws_glue_catalog_table`) or written by Glue jobs.
  Crawlers are reserved for initial discovery or schema drift.
- **Bedrock Batch Inference, not AgentCore.** Enrichment is a deterministic, high-volume
  transformation (one prompt → one response per review). AgentCore (autonomous agents
  with tool-calling and memory) is roadmapped for a future conversational analytics
  layer over Athena.
- **AWS Batch on Fargate, not Lambda.** Category files can be hundreds of MB to GB
  compressed; Lambda's 15-minute timeout and ephemeral storage limits are insufficient.
- **S3 + Athena for silver/gold, not Redshift.** Athena is fully serverless (pay-per-TB
  scanned). Redshift Serverless + Spectrum is roadmapped for when high concurrency or
  sub-second latency is required at scale.

## Repository structure

```
amazon-reviews-analyzer/
├── .claude/
│   └── CLAUDE.md                    # this file — agent context
├── .cursor/rules/project.mdc        # Cursor agent rules (alwaysApply)
├── README.md                        # architecture overview
├── docs/dev.md                      # deployment steps, IAM table, CI/CD details
├── Makefile                         # local development targets
├── pyproject.toml                   # Python deps + ruff config
├── .python-version                  # 3.12
├── config/
│   ├── config.example.yaml          # template (copy to dev.yaml / prod.yaml)
│   ├── dev.yaml
│   └── prod.yaml
├── terraform/
│   ├── providers.tf                 # terraform{} + backend s3 + provider aws (single file)
│   ├── variables.tf
│   ├── main.tf                      # module composition
│   ├── terraform.tfvars             # dev values (region, project, subnet/SG IDs)
│   └── modules/
│       ├── s3_bucket/               # S3 bucket with lifecycle, versioning, KMS (optional)
│       ├── iam/                     # least-privilege roles (skeleton)
│       ├── batch/                   # Fargate compute environment + job queue (implemented; ECR pending)
│       ├── glue/                    # catalog + PySpark jobs (skeleton)
│       ├── bedrock/                 # batch inference (skeleton)
│       ├── step_functions/          # state machine + EventBridge (skeleton)
│       ├── athena/                  # workgroup (skeleton)
│       ├── quicksight/              # dashboard (skeleton)
│       └── observability/           # CloudWatch (skeleton)
├── amazon_reviews_analyzer/
│   ├── utils/                       # shared config loader + logging
│   ├── ingestion/                   # HF download -> S3 bronze/ (+ Dockerfile)
│   ├── etl/                         # Glue PySpark jobs (silver, gold-merge)
│   └── llm/                         # prompt builder + Bedrock batch client
└── .github/
    └── workflows/
        ├── terraform.yml            # fmt + lint + validate + Trivy + plan + manual apply
        └── services.yml             # ruff + pip-audit + Trivy + build ECR + deploy Batch job
```

## Branch → environment mapping

| Branch pattern | Terraform workspace | Deploy gate |
| --- | --- | --- |
| `feature/*`, `development` | `dev` | manual (GitHub Environment) |
| `master`, `hotfix/*` | `prod` | manual (GitHub Environment) |

## Code conventions

- **Language:** all code, comments, docstrings, and documentation must be in **English**.
- **Python:** 3.12, managed with `uv`. Formatter and linter: `ruff` (line length 88,
  target `py312`, rule sets E/F/I/UP/B/W). Security audit: `pip-audit`.
- **Terraform:** >= 1.12, AWS provider ~> 6.0. `providers.tf` contains the `terraform{}`
  block, backend, and provider — do **not** split them back into separate files.
  No root `outputs.tf`; resource names use `var.project_name` and environment isolation
  comes from the default `Environment = terraform.workspace` tag. Currently only the
  `s3_bucket` and `batch` modules are instantiated in `main.tf`; all others are
  comment-only scaffolds.
- **Stubs:** all Python functions in `etl/`, `llm/`, and `ingestion/download.py` are
  stubs that raise `NotImplementedError`. Implement them before adding logic elsewhere.
- **No hardcoded bucket names.** The tfstate bucket is passed via
  `-backend-config="bucket=..."` at `terraform init`; it is never in source code.

## Local development

```bash
# Python
make install    # uv sync --all-extras --dev
make fmt        # ruff format .
make lint       # ruff format --check + ruff check
make audit      # pip-audit
make checks     # lint + audit + tf-fmt

# Terraform (ENV=dev|prod)
make tf-init    # terraform init with S3 backend-config
make tf-plan    # plan for selected ENV
make tf-apply   # apply for selected ENV (manual gate in CI)

# Docker
make build ENV=dev   # build ingestion image
```

## Terraform init command

The tfstate bucket is **not** in code — always pass it explicitly. The bucket is shared
across projects; states are isolated by `workspace_key_prefix = "amazon-reviews-analyzer"`:

```bash
cd terraform
terraform init -backend-config="bucket=<shared-tfstate-bucket>"
terraform workspace select dev   # or prod
```

State paths inside the bucket:
- `amazon-reviews-analyzer/dev/terraform.tfstate`
- `amazon-reviews-analyzer/prod/terraform.tfstate`

## MVP categories (start small, scale up)

Current dev/prod configs ingest a few small categories:
`All_Beauty`, `Gift_Cards`, `Magazine_Subscriptions` (+ `Health_and_Personal_Care` in prod).

Full dataset has 33 categories up to 571M reviews. Scale incrementally.
