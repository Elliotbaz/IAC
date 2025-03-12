data "aws_caller_identity" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  management_account_id = "097157727296"
  region      = "us-east-1"
  suffix = random_id.suffix.hex
}

provider "aws" {
  region = local.region
}

terraform {}

module "member-setup" {
  # source = "github.com/TerrazeroOrg/iac//terraform/modules/member-setup?ref=1.0.1"
  source = "../../modules/member-setup"
  project = "intraverse"
  region = local.region
  environment = "prod"
  management_account_id = local.management_account_id
  github_idp_role_arn = "arn:aws:iam::097157727296:role/intraverse-ops-github-actions"
  member_account_id = data.aws_caller_identity.current.account_id
}

output "member_account_role_arn" {
  value = module.member-setup.member_account_role_arn
}
