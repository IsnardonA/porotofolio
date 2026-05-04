output "cloud_run_url" {
  description = "URL of the deployed Cloud Run service"
  value       = google_cloud_run_service.pipeline.status[0].url
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository URL"
  value       = google_artifact_registry_repository.pipeline_repo.repository_url
}
