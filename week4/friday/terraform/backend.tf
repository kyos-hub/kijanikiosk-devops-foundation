/*
  Remote backend — Requirement 1, criterion 5.

  Points at the local MinIO container started manually before running
  pipeline.sh. MinIO exposes an S3-compatible API, so the standard S3
  backend type talks to it directly with AWS-specific validation disabled.

  Known limitation (documented in hardening-decisions.md): the S3 backend's
  native locking depends on a DynamoDB table for lock IDs; MinIO alone does
  not provide that lock table, so state locking is NOT enforced here.
*/

terraform {
  backend "s3" {
    bucket = "kijanikiosk-tfstate"
    key    = "week4/terraform.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "http://localhost:9000"
    }

    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style               = true
  }
}
