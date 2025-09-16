terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# Create Artifact Registry repository
resource "google_artifact_registry_repository" "insight_agent_repo" {
  location      = var.region
  repository_id = "insight-agent-${random_id.suffix.hex}"
  description   = "Docker repository for Insight Agent application"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}

# Create dedicated service account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "insight-agent-runner-${random_id.suffix.hex}"
  display_name = "Insight Agent Cloud Run Service Account"
  description  = "Service account for running Insight Agent on Cloud Run"
}

# Create service account for CI/CD
resource "google_service_account" "ci_cd_sa" {
  account_id   = "insight-agent-cicd-${random_id.suffix.hex}"
  display_name = "Insight Agent CI/CD Service Account"
  description  = "Service account for CI/CD operations"
}

# IAM bindings for Cloud Run service account (least privilege)
resource "google_project_iam_member" "cloud_run_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# IAM bindings for CI/CD service account
resource "google_project_iam_member" "ci_cd_artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci_cd_sa.email}"
}

resource "google_project_iam_member" "ci_cd_cloud_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.ci_cd_sa.email}"
}

resource "google_project_iam_member" "ci_cd_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.ci_cd_sa.email}"
}

resource "google_project_iam_member" "ci_cd_cloud_build" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.ci_cd_sa.email}"
}

# VPC Connector for private access (optional - for advanced scenarios)
resource "google_vpc_access_connector" "connector" {
  count = var.enable_vpc_connector ? 1 : 0

  name          = "insight-agent-connector-${random_id.suffix.hex}"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"

  depends_on = [google_project_service.required_apis]
}

# Cloud Run service
resource "google_cloud_run_v2_service" "insight_agent" {
  name         = "insight-agent-${random_id.suffix.hex}"
  location     = var.region
  ingress      = var.allow_public_access ? "INGRESS_TRAFFIC_ALL" : "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.cloud_run_sa.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    dynamic "vpc_access" {
      for_each = var.enable_vpc_connector ? [1] : []
      content {
        connector = google_vpc_access_connector.connector[0].id
      }
    }

    containers {
      image = var.container_image

      ports {
        container_port = 8080
      }

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
        cpu_idle = true
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 10
        timeout_seconds      = 5
        period_seconds       = 5
        failure_threshold    = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 30
        timeout_seconds      = 5
        period_seconds       = 60
        failure_threshold    = 3
      }
    }
  }

  depends_on = [google_project_service.required_apis]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# IAM policy for Cloud Run service (if not public)
resource "google_cloud_run_service_iam_member" "invoker" {
  count = var.allow_public_access ? 0 : 1

  location = google_cloud_run_v2_service.insight_agent.location
  project  = google_cloud_run_v2_service.insight_agent.project
  service  = google_cloud_run_v2_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.authorized_service_account_email}"
}

# Allow public access if enabled
resource "google_cloud_run_service_iam_member" "public_invoker" {
  count = var.allow_public_access ? 1 : 0

  location = google_cloud_run_v2_service.insight_agent.location
  project  = google_cloud_run_v2_service.insight_agent.project
  service  = google_cloud_run_v2_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}