# FILENAME: providers.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Using a recent version
    }
    librenms = {
      source  = "jokelyo/librenms"
      version = ">= 0.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1" # Using a stable version
    }
  }
  required_version = ">= 1.11"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "librenms" {
  host  = var.librenms_host
  token = var.librenms_token
}
