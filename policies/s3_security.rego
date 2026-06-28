package main

import rego.v1

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