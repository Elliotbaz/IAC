terraform {
  backend "s3" {
    bucket = "intraverse-dev-terraform-state-0b50c4893db71531"
    key    = "core.tfstate"
    region = "us-east-1"
  }
}