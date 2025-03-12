variable "project" {
  type = string
  default = "intraverse"
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "environment" {
  type = string
  default = "ops"
}

variable "management_account_id" {
  type = string
}

variable "member_account_id" {
  type = string
}

variable "github_idp_role_arn" {
  type = string
}