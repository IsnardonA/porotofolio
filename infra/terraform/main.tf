terraform {
  required_version = ">= 1.4.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

data "google_client_config" "default" {}

resource "google_project_service" "artifact_registry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}

resource "google_service_account" "pipeline" {
  account_id   = "data-pipeline-sa"
  display_name = "Data Pipeline Service Account"
}

resource "google_artifact_registry_repository" "pipeline_repo" {
  provider   = google
  location   = var.gcp_region
  repository_id = "data-pipeline-repo"
  format     = "DOCKER"
  description = "Docker registry for data pipeline images"
}

locals {
  cloud_run_image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.pipeline_repo.repository_id}/data-pipeline:latest"
}

resource "google_cloud_run_service" "pipeline" {
  name     = "data-pipeline"
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.pipeline.email

      containers {
        image = local.cloud_run_image

        env {
          name  = "DB_PATH"
          value = "/data/warehouse.duckdb"
        }

        env {
          name  = "GCP_PROJECT_ID"
          value = var.gcp_project_id
        }

        volume_mounts {
          name       = "data-volume"
          mount_path = "/data"
        }
      }

      volumes {
        name = "data-volume"
        empty_dir {}
      }
    }
  }

  traffics {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  service = google_cloud_run_service.pipeline.name
  location = google_cloud_run_service.pipeline.location
  role    = "roles/run.invoker"
  member  = "allUsers"
}
