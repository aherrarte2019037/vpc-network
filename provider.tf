# provider.tf
# Configuración del proveedor de Google Cloud Platform

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "still-smithy-475313-s3"
  region  = "us-central1"
}
