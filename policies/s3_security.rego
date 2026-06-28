package main

import rego.v1

has_s3_bucket if {
  count(object.get(input.resource, "aws_s3_bucket", {})) > 0
}

deny contains msg if {
  has_s3_bucket
  count(object.get(input.resource, "aws_s3_bucket_public_access_block", {})) == 0

  msg := "S3 buckets must define aws_s3_bucket_public_access_block"
}

deny contains msg if {
  some name
  pab := input.resource.aws_s3_bucket_public_access_block[name][_]
  pab.block_public_acls != true

  msg := sprintf(
    "S3 public access block %q must set block_public_acls = true",
    [name],
  )
}

deny contains msg if {
  some name
  pab := input.resource.aws_s3_bucket_public_access_block[name][_]
  pab.ignore_public_acls != true

  msg := sprintf(
    "S3 public access block %q must set ignore_public_acls = true",
    [name],
  )
}

deny contains msg if {
  some name
  pab := input.resource.aws_s3_bucket_public_access_block[name][_]
  pab.block_public_policy != true

  msg := sprintf(
    "S3 public access block %q must set block_public_policy = true",
    [name],
  )
}

deny contains msg if {
  some name
  pab := input.resource.aws_s3_bucket_public_access_block[name][_]
  pab.restrict_public_buckets != true

  msg := sprintf(
    "S3 public access block %q must set restrict_public_buckets = true",
    [name],
  )
}

deny contains msg if {
  has_s3_bucket
  count(object.get(input.resource, "aws_s3_bucket_versioning", {})) == 0

  msg := "S3 buckets must define aws_s3_bucket_versioning with versioning enabled"
}

deny contains msg if {
  has_s3_bucket
  count(object.get(input.resource, "aws_s3_bucket_server_side_encryption_configuration", {})) == 0

  msg := "S3 buckets must define server-side encryption"
}