terraform {
  backend "s3" {
    bucket = "intraverse-ops-terraform-state-feba35c8"
    key    = "TerraZero_QA/main.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::602161100705:role/intraverse-qa-github-actions-member"
  }
}

resource "random_id" "suffix" {
  byte_length = 8
}

locals {
  project     = "intraverse"
  region      = "us-east-1"
  environment = "qa"
  suffix      = random_id.suffix.hex
  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

output "suffix" {
  value = local.suffix
}
