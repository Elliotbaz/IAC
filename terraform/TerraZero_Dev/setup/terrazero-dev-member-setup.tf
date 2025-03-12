data "aws_caller_identity" "current" {}

locals {
  management_account_id = "097157727296"
  region      = "us-east-1"
  common_tags = {
    Project     = "intraverse"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

provider "aws" {
  region = local.region
}

terraform {}

module "member-setup" {
  # source = "github.com/TerrazeroOrg/iac//terraform/modules/member-setup?ref=v1.0.14"
  source = "../../modules/member-setup"
  
  project = "intraverse"
  region = local.region
  environment = "dev"
  management_account_id = local.management_account_id
  github_idp_role_arn = "arn:aws:iam::097157727296:role/intraverse-ops-github-actions"
  member_account_id = data.aws_caller_identity.current.account_id
}

##############
# Users
##############

# Create a User for Fastlane Signing Certificates
resource "aws_iam_user" "fastlane" {
  name = "fastlane"
  tags = local.common_tags
}

# Create a Policy for Fastlane Signing Certificates
resource "aws_iam_policy" "fastlane" {
  name        = "fastlane-s3"
  description = "Policy for Fastlane Signing Certificates"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

# Attach the Policy to the User
resource "aws_iam_user_policy_attachment" "fastlane" {
  user       = aws_iam_user.fastlane.name
  policy_arn = aws_iam_policy.fastlane.arn
}

output "member_account_role_arn" {
  value = module.member-setup.member_account_role_arn
}
