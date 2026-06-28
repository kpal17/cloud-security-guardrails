variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)

  default = {
    Project     = "Secure Cloud Storage Guardrails"
    ManagedBy   = "Terraform"
    Environment = "lab"
  }
}