SHELL := /bin/bash

.PHONY: up terraform-init terraform-apply lint

up:
	docker compose up --build

terraform-init:
	cd infra/terraform && terraform init

terraform-apply:
	cd infra/terraform && terraform apply -var="gcp_project_id=${GCP_PROJECT_ID}"

lint:
	flake8 src/dlt_pipelines
