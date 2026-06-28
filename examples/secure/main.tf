terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "secure_storage" {
  source = "../../infra"

  bucket_name = "secure-guardrails-${random_id.suffix.hex}"

  tags = {
    Project            = "Secure Cloud Storage Guardrails"
    ManagedBy          = "Terraform"
    Environment        = "lab"
    DataClassification = "confidential"
    Owner              = "conk"
  }
}