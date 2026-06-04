.DEFAULT_GOAL := help
SHELL := /bin/bash

ENV ?= dev
TF_DIR := terraform
TF_STATE_BUCKET ?= my-org-tfstate

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ----- Python -----
.PHONY: install
install: ## Install dependencies with uv
	uv sync --all-extras --dev

.PHONY: fmt
fmt: ## Format code (ruff format)
	uv run ruff format .

.PHONY: lint
lint: ## Lint + format check (ruff)
	uv run ruff format --check .
	uv run ruff check .

.PHONY: audit
audit: ## Dependency security audit (pip-audit)
	uv run pip-audit

# ----- Terraform -----
.PHONY: tf-fmt
tf-fmt: ## terraform fmt check
	cd $(TF_DIR) && terraform fmt -check -recursive

.PHONY: tf-init
tf-init: ## terraform init (S3 backend)
	cd $(TF_DIR) && terraform init -backend-config="bucket=$(TF_STATE_BUCKET)"

.PHONY: tf-validate
tf-validate: ## terraform validate
	cd $(TF_DIR) && terraform init -backend=false && terraform validate

.PHONY: tf-plan
tf-plan: ## terraform plan (ENV=dev|prod)
	cd $(TF_DIR) && terraform workspace select -or-create $(ENV) && \
		terraform plan -var-file="environments/$(ENV).tfvars"

.PHONY: tf-apply
tf-apply: ## terraform apply (ENV=dev|prod)
	cd $(TF_DIR) && terraform workspace select -or-create $(ENV) && \
		terraform apply -var-file="environments/$(ENV).tfvars"

# ----- Docker -----
.PHONY: build
build: ## Build the ingestion job Docker image
	docker build -f amazon_reviews_analyzer/ingestion/Dockerfile -t amazon-reviews-analyzer-ingestion:$(ENV) .

.PHONY: checks
checks: lint audit tf-fmt ## Run all local checks
