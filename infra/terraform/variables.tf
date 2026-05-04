variable "gcp_project_id" {
  description = "Google Cloud project ID used for resource creation"
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region for Cloud Run and Artifact Registry"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Google Cloud zone for the provider"
  type        = string
  default     = "us-central1-a"
}
