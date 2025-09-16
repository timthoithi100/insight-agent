variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "container_image" {
  description = "The container image to deploy"
  type        = string
  default     = "gcr.io/cloudrun/hello"  # Placeholder, will be updated by CI/CD
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "production"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "allow_public_access" {
  description = "Whether to allow public access to the Cloud Run service"
  type        = bool
  default     = false
}

variable "authorized_service_account_email" {
  description = "Email of the service account authorized to invoke the service (when not public)"
  type        = string
  default     = ""
}

variable "enable_vpc_connector" {
  description = "Whether to enable VPC connector for private access"
  type        = bool
  default     = false
}