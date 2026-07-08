terraform {
  required_version = ">= 1.6.0"

  backend "s3" {}

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

data "aws_caller_identity" "current" {}

resource "random_id" "state_suffix" {
  byte_length = 4
}

module "terraform_state" {
  source = "../infra"

  bucket_name = "kpal-guardrails-tfstate-${data.aws_caller_identity.current.account_id}-${random_id.state_suffix.hex}"

  tags = {
    Project            = "Secure Cloud Storage Guardrails"
    ManagedBy          = "Terraform"
    Environment        = "lab"
    DataClassification = "confidential"
    Purpose            = "terraform-state"
    Owner              = "kpal"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Project   = "Secure Cloud Storage Guardrails"
    ManagedBy = "Terraform"
    Purpose   = "github-actions-oidc"
  }
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:kpal17/cloud-security-guardrails:ref:refs/heads/main"
      ]
    }
  }
}

data "aws_iam_policy_document" "terraform_deployer_permissions" {
  statement {
    sid    = "ListAllBucketsForTerraform"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:CreateBucket"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReadAndLockTerraformState"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]

    resources = [
      module.terraform_state.bucket_arn
    ]
  }

  statement {
    sid    = "ManageTerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${module.terraform_state.bucket_arn}/secure-storage/*"
    ]
  }

  statement {
    sid    = "ManageProjectBuckets"
    effect = "Allow"

    actions = [
      "s3:DeleteBucket",
      "s3:GetBucketAcl",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketCORS",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketWebsite",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:DeleteBucketOwnershipControls",
      "s3:DeleteBucketPolicy",
      "s3:DeleteBucketPublicAccessBlock",
      "s3:DeleteBucketTagging"
    ]

    resources = [
      "arn:aws:s3:::secure-guardrails-*"
    ]
  }
}

resource "aws_iam_role" "terraform_deployer" {
  name               = "terraform-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json

  tags = {
    Project            = "Secure Cloud Storage Guardrails"
    ManagedBy          = "Terraform"
    Environment        = "lab"
    SeparationOfDuties = "deployment"
  }
}

resource "aws_iam_role_policy" "terraform_deployer" {
  name   = "terraform-deployer-s3-policy"
  role   = aws_iam_role.terraform_deployer.id
  policy = data.aws_iam_policy_document.terraform_deployer_permissions.json
}

output "terraform_state_bucket_name" {
  description = "Set this as GitHub variable TF_STATE_BUCKET."
  value       = module.terraform_state.bucket_name
}

output "terraform_deployer_role_arn" {
  description = "Set this as GitHub variable AWS_DEPLOY_ROLE_ARN."
  value       = aws_iam_role.terraform_deployer.arn
}

data "aws_iam_policy_document" "security_auditor_trust" {
  statement {
    sid    = "AllowGitHubActionsFromMain"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:kpal17/cloud-security-guardrails:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "security_auditor" {
  name               = "security-auditor"
  assume_role_policy = data.aws_iam_policy_document.security_auditor_trust.json

  tags = {
    Project            = "Secure Cloud Storage Guardrails"
    ManagedBy          = "Terraform"
    Environment        = "lab"
    SeparationOfDuties = "runtime-audit"
  }
}

resource "aws_iam_role_policy_attachment" "security_auditor_security_audit" {
  role       = aws_iam_role.security_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "security_auditor_view_only" {
  role       = aws_iam_role.security_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

output "security_auditor_role_arn" {
  description = "Set this as GitHub variable AWS_AUDIT_ROLE_ARN."
  value       = aws_iam_role.security_auditor.arn
}

resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}