# get the account id
data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    "Environment" = "${var.environment}"
    "Owner"       = "${var.owner}"
    "Project"     = "${var.project}"
    "ManagedBy"   = "Terraform"
  }
  prefix = lower("${var.project}-${var.environment}")
  MetricsCollectionInterval = 60
  InstanceID                = aws_instance.poc
  LogGroupName              = aws_cloudwatch_log_group.poc
  LogStreamName             = "poc"
  account_id                = data.aws_caller_identity.current.account_id
}