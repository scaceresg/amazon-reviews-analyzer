# Development and deployment guide

Technical documentation for the Amazon Reviews Analyzer project: infrastructure deployment, IAM permissions, CI/CD pipeline, and pending work.

---

## Table of contents

- [Step-by-step deployment (from scratch)](#step-by-step-deployment-from-scratch)
- [Minimum IAM permissions per service](#minimum-iam-permissions-per-service)
- [CI/CD](#cicd)
- [Pending work](#pending-work)

---

## Step-by-step deployment (from scratch)

> Requirements: AWS account, [AWS CLI](https://docs.aws.amazon.com/cli/), [Terraform](https://developer.hashicorp.com/terraform) >= 1.12, [uv](https://docs.astral.sh/uv/), Docker, model access enabled in Amazon Bedrock, and QuickSight subscription.

### 0. Terraform backend (manual, one-time)

Create from the **AWS Management Console** a shared S3 bucket across projects (e.g. `my-org-tfstate-<account_id>`), with versioning and public access block enabled.

The bucket is **not hardcoded** in the code; it is passed at `init` time with `-backend-config`:

```bash
terraform init -backend-config="bucket=<bucket-name>"
```

The backend uses **native S3 locking** (`use_lockfile = true`, Terraform >= 1.12), so **DynamoDB is not required**.

States are organized by project and workspace inside the bucket:

```
<bucket>/
  amazon-reviews-analyzer/
    dev/terraform.tfstate    ← dev workspace
    prod/terraform.tfstate   ← prod workspace
```

### 1. Initialize and select workspace

```bash
cd terraform
terraform init -backend-config="bucket=<shared-tfstate-bucket>"
terraform workspace new dev    # and/or prod
terraform workspace select dev
```

### 2. S3 data lake buckets

Module `s3_bucket` (instantiated twice in `main.tf`): creates **2 buckets per environment**:

| Bucket | Contents |
| --- | --- |
| `<prefix>-datalake` | Zones as prefixes: `bronze/`, `silver/`, `gold/`, `scripts/` |
| `<prefix>-athena-results` | Athena query results (30-day expiry lifecycle) |

The lifecycle that transitions and expires data in the `bronze/` prefix is applied with a prefix filter inside the `datalake` bucket. KMS encryption is available via the `kms_key_arn` module variable; it is not currently wired in `main.tf`.

### 3. IAM roles and policies

Module `iam` (skeleton): defines one role per service with least-privilege permissions — see [IAM table](#minimum-iam-permissions-per-service). **Not yet implemented.**

### 4. Ingestion: ECR + AWS Batch

Module `batch` (partially implemented): Fargate compute environment and job queue. **ECR repository not yet provisioned** — needs to be added to the `batch` module or as a separate resource in `main.tf`.

### 5. Glue (catalog + jobs)

Module `glue` (skeleton): Glue Data Catalog database, Glue Jobs (`silver`, `gold-merge`) with scripts at `s3://<prefix>-datalake/scripts/`. Optional crawler for schema discovery/drift. **Not yet implemented.**

### 6. Bedrock (LLM batch)

Enable the model in the **Bedrock console** (Management Console → Bedrock → Model access). Module `bedrock` (skeleton): batch inference IAM role with access to the I/O prefixes in the `datalake` bucket. **Not yet implemented.**

### 7. Orchestration: Step Functions + EventBridge

Module `step_functions` (skeleton): state machine coordinating ingestion → silver → Bedrock batch → gold; EventBridge Scheduler rule. **Not yet implemented.**

### 8. Query: Athena

Module `athena` (skeleton): dedicated workgroup pointing to the `<prefix>-athena-results` bucket. **Not yet implemented.**

### 9. Visualization: QuickSight

Module `quicksight` (skeleton): Athena and S3 permissions, data source, SPICE dataset, and dashboard. Requires a QuickSight subscription. **Not yet implemented.**

### 10. Observability

Module `observability` (skeleton): CloudWatch log groups, alarms, and cost tags. **Not yet implemented.**

### Apply

```bash
# From terraform/
terraform workspace select dev   # or prod
terraform plan
terraform apply                  # gated/manual in CI
```

Variable values (region, project name, subnet IDs, security group IDs) are declared in `terraform/terraform.tfvars`.

---

## Minimum IAM permissions per service

Principle of **least privilege**: each role only accesses the resources and prefixes it needs. Replace `*` with concrete ARNs in the implementation.

| Role | Key actions | Resources |
| --- | --- | --- |
| **Batch / Fargate (task role)** | `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`; `logs:CreateLogStream`, `logs:PutLogEvents`; `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, `ecr:GetAuthorizationToken` | Datalake bucket (prefix `bronze/`); job log group; ECR repo |
| **Glue job role** | `s3:GetObject`, `s3:PutObject`, `s3:ListBucket`; `glue:GetTable`, `glue:CreateTable`, `glue:UpdateTable`, `glue:BatchCreatePartition`; `logs:*` for job; `kms:Encrypt`, `kms:Decrypt`, `kms:GenerateDataKey` | Datalake bucket (prefixes `silver/`, `gold/`, `scripts/`); catalog database; KMS key |
| **Bedrock batch role** | `s3:GetObject` (input), `s3:PutObject` (output); `bedrock:CreateModelInvocationJob`, `bedrock:GetModelInvocationJob`, `bedrock:StopModelInvocationJob`, `bedrock:InvokeModel`; `kms:*` data key | Datalake bucket (batch I/O prefixes); Bedrock model/region; KMS |
| **Step Functions role** | `batch:SubmitJob`, `batch:DescribeJobs`; `glue:StartJobRun`, `glue:GetJobRun`; `bedrock:CreateModelInvocationJob`, `bedrock:GetModelInvocationJob`; `iam:PassRole` (scoped) | Job queue/definition ARNs, Glue jobs, roles to pass |
| **Athena (workgroup) + QuickSight** | `athena:StartQueryExecution`, `athena:GetQueryResults`; `glue:GetTable`, `glue:GetPartitions`; `s3:GetObject`/`PutObject` on results; `s3:GetObject` on `gold/` | Workgroup; catalog database; `athena-results` bucket; `gold/` prefix in datalake |
| **CI/CD (OIDC GitHub Actions)** | `sts:AssumeRoleWithWebIdentity`; deployment permissions per service (Terraform plan/apply, ECR push, `s3:PutObject` on `scripts/`) | Federated role restricted by `repo:org/repo:ref` |

---

## CI/CD

GitHub Actions with **OIDC** authentication to AWS (no long-lived keys). Branch-to-workspace/environment mapping:

| Branch | Workspace / Environment | Apply |
| --- | --- | --- |
| `feature/*`, `development` | **dev** | manual after merge |
| `master`, `hotfix/*` | **prod** | manual after merge |

- **`terraform apply` is always manual**: executed after merge via **GitHub Environments** with *required reviewers* (approval gate).
- No bucket name or infrastructure configuration is hardcoded in the code. **GitHub Repository Variables** (not secrets) are used for non-sensitive values.

### Required GitHub Repository Variables

Configure in **Settings → Secrets and variables → Variables → New repository variable**:

| Variable | Example | Used in |
| --- | --- | --- |
| `TF_VERSION` | `1.12.0` | `terraform.yml` |
| `PYTHON_VERSION` | `3.12` | `services.yml` |
| `PROJECT_NAME` | `amazon-reviews-analyzer` | `services.yml` |
| `PROJECT_DIR_NAME` | `amazon_reviews_analyzer` | `services.yml` |
| `ECR_REPOSITORY` | `amazon-reviews-analyzer` | `services.yml` |
| `DATALAKE_BUCKET_NAME` | `amazon-reviews-analyzer-datalake` | `services.yml` |
| `BATCH_JOB_NAME` | `amazon-reviews-analyzer` | `services.yml` |

### Required GitHub Secrets

Configure in **Settings → Secrets and variables → Secrets**:

| Secret | Description |
| --- | --- |
| `AWS_INFRA_ROLE_ARN` | ARN of the IAM role federated with OIDC for deploying infrastructure and services |
| `AWS_REGION` | AWS region (e.g. `us-east-1`) |
| `TF_STATE_BUCKET` | Name of the shared S3 bucket for Terraform state files |
| `BATCH_TASK_ROLE_ARN` | ARN of the IAM role assumed by the Batch Fargate task (will be an output of the `iam` module once implemented) |
| `BATCH_EXECUTION_ROLE_ARN` | ARN of the ECS execution role for Fargate (will be an output of the `iam` module once implemented) |

### Workflow `terraform.yml`

Location: [`.github/workflows/terraform.yml`](../.github/workflows/terraform.yml)

1. `terraform fmt -check -recursive`
2. `tflint`
3. `terraform init -backend=false` + `terraform validate`
4. **Trivy** security scan (`aquasecurity/trivy-action`, config scan, exit-code 1 on HIGH/CRITICAL)
5. `terraform plan` in the corresponding workspace (on PRs and push)
6. `terraform apply` in a separate job, *gated* by GitHub Environment (manual approval)

### Workflow `services.yml`

Location: [`.github/workflows/services.yml`](../.github/workflows/services.yml)

Jobs (in order):

1. **`resolve-env`** — maps branch to environment (`dev` / `prod`).
2. **`quality-checks`** — `uv run ruff format --check` + `uv run ruff check`.
3. **`security-audit`** — `uv run pip-audit` + Trivy config scan over `amazon_reviews_analyzer/`.
4. **`build-ingestion-job`** — ECR login, Docker build and push with tag `<env>-<sha::7>`, exposes image URI as output.
5. **`deploy-ingestion-job`** *(development / master only)* — registers a new Batch job definition (`aws batch register-job-definition`) for the pushed image (1 vCPU, 2048 MB, awslogs driver).

> **Note:** uploading Glue/LLM scripts to `s3://<datalake-bucket>/scripts/` is currently commented out (lines 158–164 of `services.yml`). It will be re-enabled once the Glue module is implemented.

---

## Pending work

### Terraform modules to implement

The following modules exist as comment-only scaffolds in `terraform/modules/` and need to be coded before the full pipeline can run. Once each module is implemented, uncomment and wire its entry in `terraform/main.tf`.

| Module | What to implement |
| --- | --- |
| `iam` | Least-privilege roles: Batch task role, Glue job role, Bedrock batch role, Step Functions role, CI/CD OIDC role |
| `glue` | Glue Data Catalog database, `silver` and `gold-merge` PySpark jobs with scripts at `s3://<prefix>-datalake/scripts/`, explicit table definitions; optional crawler |
| `bedrock` | Batch inference IAM role + S3 I/O prefixes in the datalake; enable Model Access in the Bedrock console first |
| `step_functions` | State machine (ingest → silver → bedrock → gold) + EventBridge Scheduler rule |
| `athena` | Dedicated workgroup pointing to `<prefix>-athena-results` |
| `quicksight` | Athena data source, SPICE dataset, dashboard; requires QuickSight subscription |
| `observability` | CloudWatch log groups and alarms for Batch, Glue, Bedrock, and Step Functions |

### Additional infrastructure

- **ECR repository**: the `batch` module does not yet provision an ECR repo. Add it to the module or as a standalone resource in `main.tf`.
- **KMS CMK**: the `s3_bucket` module accepts a `kms_key_arn` variable. Decide whether to use a customer-managed key; if so, provision it and pass it to both bucket instantiations in `main.tf`.
- **`terraform.tfvars`**: currently contains dev VPC subnet and security group IDs. When a prod environment with different networking is introduced, values per environment will need to be separated.

### CI/CD services

- **Re-enable Glue/LLM script upload** in `services.yml` (lines 158–164) once the Glue module and `scripts/` prefix are in place.
- **Glue job update step**: add a deploy step to update Glue job definitions (script S3 paths, PySpark version, worker config) once the `glue` module is implemented.
- **`BATCH_TASK_ROLE_ARN` / `BATCH_EXECUTION_ROLE_ARN`**: currently GitHub Secrets set manually. Once the `iam` module outputs these ARNs, wire them from Terraform state outputs and remove the manual secrets.

### Python code

| File | What to implement |
| --- | --- |
| `ingestion/download.py::download_category()` | Real HF → S3 streaming download (currently raises `NotImplementedError` on the non-dry-run path) |
| `etl/silver_job.py::run()` | PySpark bronze → silver ETL (parse JSONL.gz, clean, deduplicate, write Parquet) |
| `etl/gold_merge_job.py::run()` | PySpark silver + LLM enrichment → gold merge |
| `llm/prepare_prompts.py::build_batch_input()` | Build JSONL batch input file for Bedrock |
| `llm/bedrock_batch.py::submit_batch_job()` | Submit and poll a Bedrock `CreateModelInvocationJob` |

> No `tests/` directory exists. Add unit tests incrementally as stubs are implemented.
