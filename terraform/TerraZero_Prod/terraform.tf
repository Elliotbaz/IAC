terraform {
  backend "s3" {
    bucket = "intraverse-ops-terraform-state-feba35c8"
    key    = "TerraZero_Prod/main.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::189846331552:role/intraverse-prod-github-actions-member"
  }
}

output "test" {
  value = "test"
}