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
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "librenms" {
  host  = var.librenms_host
  token = var.librenms_token
}
