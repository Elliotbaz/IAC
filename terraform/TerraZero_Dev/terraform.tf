terraform {
  backend "s3" {
    bucket = "intraverse-ops-terraform-state-feba35c8"
    key    = "TerraZero_Dev/main.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::585415957264:role/intraverse-dev-github-actions-member"
  }
}

# Create a Bucket for Fastlane Signing Certificates
resource "aws_s3_bucket" "fastlane" {
  bucket = "fastlane-signing-certificates-${local.suffix}"
  tags   = local.common_tags
}

output "suffix" {
  value = local.suffix
}

output "bucket" {
  value = "fastlane-signing-certificates-${local.suffix}"
}
