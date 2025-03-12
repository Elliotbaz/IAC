resource "random_id" "suffix" {
  byte_length = 4
}

# account id
data "aws_caller_identity" "current" {}

locals {
    project = "Intraverse"
    environment = "Production"
    region = "us-east-1"
    suffix      = random_id.suffix.hex
    prefix = lower("${local.project}-prod")
    account_id = data.aws_caller_identity.current.account_id
    certificate_arn = "arn:aws:acm:us-east-1:189846331552:certificate/bee2dcd0-1f4b-450c-9ec4-40b645ff7d68"
    dcv_ami_id = "ami-0f696eae9eef3996d"
    dcv_ami_version = "1.3.11"
    intraverse_version = "1.3.6"

    common_tags = { 
        Project     = local.project
        Environment = local.environment
        ManagedBy   = "Terraform"
        Owner       = "jay@terrazero.com"
    }
}