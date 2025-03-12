####################
# Terraform
####################

provider "aws" {
  region = local.region
}

terraform {
  backend "s3" {
    bucket = "intraverse-ops-terraform-state-feba35c8"
    key    = "management/terraform.tfstate"
    region = "us-east-1"
  }
}

####################
# Variables
####################

# Random ID for suffix
resource "random_id" "suffix" {
  byte_length = 4
}

# Get the account ID of the management account
data "aws_caller_identity" "current" {}

# Local variables
locals {
    project     = "intraverse"
    region      = "us-east-1"
    environment = "ops"
    management_account_id = data.aws_caller_identity.current.account_id
    suffix      = random_id.suffix.hex
    create_state_bucket = "aws s3api create-bucket --bucket ${local.project}-${local.environment}-terraform-state-${local.suffix} --region ${local.region}"
    common_tags = {
        Project     = local.project
        Environment = local.environment
        ManagedBy   = "Terraform"
    }
}

#######################################
# OIDC Identity Provider for GitHub
#######################################

# Configure the OIDC identity provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "${local.project}-${local.environment}-github-actions"
  description = "Role for GitHub Actions to assume in the management account to manage state in the central bucket and modify infrastructure resources in member accounts."
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:TerrazeroOrg/iac:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.project}-${local.environment}-terraform-state-${local.suffix}",
          "arn:aws:s3:::${local.project}-${local.environment}-terraform-state-${local.suffix}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::602161100705:role/intraverse-qa-github-actions-member",
          "arn:aws:iam::585415957264:role/intraverse-dev-github-actions-member",
          "arn:aws:iam::189846331552:role/intraverse-prod-github-actions-member",
          "arn:aws:iam::339712848990:role/intraverse-demo-github-actions-member"
        ]
      }
    ]
  })
}

# Outputs
output "suffix" {
  value = local.suffix 
}

output "aws_cli_create_state_bucket_command" {
  value = local.create_state_bucket
  description = "In case anything fails, here is the commmand to run manually."
}

output "state_bucket_name" {
  value = "${local.project}-${local.environment}-terraform-state-${local.suffix}"
  description = "Name of the S3 bucket to store Terraform state."
}

output "management_account_info" {
  value = {
    account_id = local.management_account_id
    region = local.region
  }
  description = "Information about the management account."
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
  description = "ARN of the role for GitHub Actions in the management account."
}