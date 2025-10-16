# variables.tf
# Variables parametrizables para la configuración de Terraform

variable "project_id" {
  description = "ID del proyecto de Google Cloud"
  type        = string
}

variable "region" {
  description = "Región de GCP donde se desplegará la infraestructura"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "Nombre de la VPC principal"
  type        = string
  default     = "vpc-network"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}
