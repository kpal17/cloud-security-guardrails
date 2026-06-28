# !!! INTENTIONALLY INSECURE TEST FIXTURE !!!
# This directory exists to prove that security checks block unsafe Terraform
# Never run terraform apply from this directory

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "bad" {
  bucket = "insecure-guardrails-demo-do-not-apply"

  tags = {
    Project     = "Secure Cloud Storage Guardrails"
    ManagedBy   = "Terraform"
    Environment = "lab"
    Purpose     = "intentionally-insecure-example"
  }
}

resource "aws_s3_bucket_public_access_block" "bad" {
  bucket = aws_s3_bucket.bad.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "public_read" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.bad.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "bad" {
  bucket = aws_s3_bucket.bad.id
  policy = data.aws_iam_policy_document.public_read.json
}