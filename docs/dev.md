# Guía de desarrollo y despliegue

Documentación técnica del proyecto Amazon Reviews Analyzer: despliegue de infraestructura, permisos IAM y pipeline de CI/CD.

---

## Tabla de contenidos

- [Despliegue paso a paso (desde cero)](#despliegue-paso-a-paso-desde-cero)
- [Permisos IAM mínimos por servicio](#permisos-iam-mínimos-por-servicio)
- [CI/CD](#cicd)

---

## Despliegue paso a paso (desde cero)

> Requiere: cuenta AWS, [AWS CLI](https://docs.aws.amazon.com/cli/), [Terraform](https://developer.hashicorp.com/terraform) >= 1.10, [uv](https://docs.astral.sh/uv/), Docker, acceso habilitado a modelos en Amazon Bedrock y suscripción a QuickSight.

### 0. Backend de Terraform (manual, una sola vez)

Crear desde la **consola UI de AWS** un bucket S3 para el estado de Terraform (p. ej. `amazon-reviews-analyzer-tfstate-<account_id>`), con versioning y bloqueo de acceso público activados.

El bucket **no está hardcodeado** en el código; se pasa en el momento del `init` con `-backend-config`:

```bash
terraform init -backend-config="bucket=amazon-reviews-analyzer-tfstate-<account_id>"
```

El backend usa **bloqueo nativo de S3** (`use_lockfile = true`, Terraform >= 1.10), por lo que **no se requiere DynamoDB**.

### 1. Inicializar y seleccionar workspace

```bash
cd terraform
terraform init -backend-config="bucket=amazon-reviews-analyzer-tfstate-<account_id>"
terraform workspace new dev    # y/o prod
terraform workspace select dev
```

### 2. KMS + buckets S3 del data lake

Módulo `s3_lake`: crea la KMS key y **2 buckets por ambiente**:

| Bucket | Contenido |
| --- | --- |
| `<prefix>-datalake` | Zonas como prefijos: `bronze/`, `silver/`, `gold/`, `scripts/` |
| `<prefix>-athena-results` | Resultados de queries de Athena |

El lifecycle que transiciona y expira datos del prefijo `bronze/` se aplica con un filtro de prefijo dentro del bucket `datalake`.

### 3. Roles y políticas IAM

Módulo `iam`: define un rol por servicio con permisos mínimos (ver [tabla IAM](#permisos-iam-mínimos-por-servicio)).

### 4. Ingesta: ECR + AWS Batch

Módulo `batch`: repositorio ECR, *compute environment* Fargate, *job queue* y *job definition* que ejecuta el contenedor de `amazon_reviews_analyzer/ingestion/`.

### 5. Glue (catálogo + jobs)

Módulo `glue`: database del Data Catalog, Glue Jobs (`silver`, `gold-merge`) con scripts en `s3://<prefix>-datalake/scripts/`. Crawler opcional para descubrimiento/drift de esquema.

### 6. Bedrock (LLM batch)

Habilitar el modelo en la **consola de Bedrock** (Management Console → Bedrock → Model access). Módulo `bedrock`: rol de batch inference con acceso a los prefijos de I/O en el bucket `datalake`.

### 7. Orquestación: Step Functions + EventBridge

Módulo `step_functions`: state machine que coordina ingesta → silver → Bedrock batch → gold; schedule de EventBridge.

### 8. Consulta: Athena

Módulo `athena`: workgroup dedicado apuntando al bucket `<prefix>-athena-results`.

### 9. Visualización: QuickSight

Módulo `quicksight`: permisos a Athena y S3, fuente de datos, dataset SPICE y dashboard.

### 10. Observabilidad

Módulo `observability`: log groups de CloudWatch, alarmas y tags de costo.

### Aplicar

```bash
# Desde terraform/
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars   # gated/manual en CI
```

---

## Permisos IAM mínimos por servicio

Principio de **menor privilegio**: cada rol solo accede a los recursos y prefijos que necesita. Reemplazar `*` por ARNs concretos en la implementación.

| Rol | Acciones clave | Recursos |
| --- | --- | --- |
| **Batch / Fargate (task role)** | `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`; `logs:CreateLogStream`, `logs:PutLogEvents`; `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, `ecr:GetAuthorizationToken` | Bucket datalake (prefijo `bronze/`); log group del job; repo ECR |
| **Glue job role** | `s3:GetObject`, `s3:PutObject`, `s3:ListBucket`; `glue:GetTable`, `glue:CreateTable`, `glue:UpdateTable`, `glue:BatchCreatePartition`; `logs:*` del job; `kms:Encrypt`, `kms:Decrypt`, `kms:GenerateDataKey` | Bucket datalake (prefijos `silver/`, `gold/`, `scripts/`); database del catálogo; KMS key |
| **Bedrock batch role** | `s3:GetObject` (input), `s3:PutObject` (output); `bedrock:CreateModelInvocationJob`, `bedrock:GetModelInvocationJob`, `bedrock:StopModelInvocationJob`, `bedrock:InvokeModel`; `kms:*` data key | Bucket datalake (prefijos de I/O del batch); modelo/región de Bedrock; KMS |
| **Step Functions role** | `batch:SubmitJob`, `batch:DescribeJobs`; `glue:StartJobRun`, `glue:GetJobRun`; `bedrock:CreateModelInvocationJob`, `bedrock:GetModelInvocationJob`; `iam:PassRole` (acotado) | ARNs de job queue/definition, Glue jobs, roles a pasar |
| **Athena (workgroup) + QuickSight** | `athena:StartQueryExecution`, `athena:GetQueryResults`; `glue:GetTable`, `glue:GetPartitions`; `s3:GetObject`/`PutObject` en resultados; `s3:GetObject` en `gold/` | Workgroup; database del catálogo; bucket `athena-results`; prefijo `gold/` en datalake |
| **CI/CD (OIDC GitHub Actions)** | `sts:AssumeRoleWithWebIdentity`; permisos de despliegue por servicio (Terraform plan/apply, push ECR, `s3:PutObject` en `scripts/`) | Rol federado restringido por `repo:org/repo:ref` |

---

## CI/CD

GitHub Actions con autenticación **OIDC** hacia AWS (sin llaves de larga vida). Mapeo de ramas a workspace/ambiente de Terraform:

| Ramas | Workspace / Ambiente | Apply |
| --- | --- | --- |
| `feature/*`, `development` | **dev** | manual tras merge |
| `master`, `hotfix/*` | **prod** | manual tras merge |

- El **`terraform apply` siempre es manual**: se ejecuta tras el merge mediante **GitHub Environments** con *required reviewers* (gate de aprobación).
- El bucket de tfstate se pasa con `-backend-config` en `terraform init`; no está hardcodeado en el código.

### Workflow `terraform.yml`

Ubicación: [`.github/workflows/terraform.yml`](../.github/workflows/terraform.yml)

1. `terraform fmt -check -recursive`
2. `tflint`
3. `terraform init -backend=false` + `terraform validate`
4. `tfsec` (seguridad de IaC)
5. `terraform plan` en el workspace correspondiente (en PRs y push)
6. `terraform apply` en job separado, *gated* por GitHub Environment (aprobación manual)

### Workflow `python-services.yml`

Ubicación: [`.github/workflows/python-services.yml`](../.github/workflows/python-services.yml)

1. Setup `uv` + Python 3.12
2. **Format check**: `uv run ruff format --check .`
3. **Lint**: `uv run ruff check .`
4. **Security/audit**: `uv run pip-audit`
5. **Build & deploy** (*gated* por ambiente):
   - Build y push de la imagen Docker de `ingestion/` a Amazon ECR
   - Subida de scripts Glue (`etl/`) y artefactos LLM (`llm/`) al prefijo `scripts/` del bucket `<prefix>-datalake`
   - Actualización de definiciones (Batch job definition, Glue jobs) según ambiente
