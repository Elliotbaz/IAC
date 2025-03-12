terraform {
  backend "s3" {
    bucket = "intraverse-ops-terraform-state-feba35c8"
    key    = "TerraZero_Dev/dcv-server-host/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::585415957264:role/intraverse-dev-github-actions-member"
  }
}

variable "ami_hash" {
  type    = string
  default = "cd3deba"
}

variable "game_version" {
  type    = string
  default = "1_3_9"
}

variable "ami_id" {
  type    = string
  default = "ami-0d00d12af98ec6a9f"
}

module "dcv-server-host" {
  source = "../../modules/dcv-server-host"

  ami_hash = var.ami_hash 
  game_version = var.game_version
  ami_id = var.ami_id
  instance_type = "g4dn.xlarge"
  key_name = "intraverse-development-dcv-server"
  iam_instance_profile = "intraverse-dev-dcv-builder-18f71b13"
  subnet_id = "subnet-0c5e5f6b346f46246"
  security_group_id = "sg-037d7123ccd862c41"
  region = "us-east-1"
  log_group_name = "intraverse-dev-dcv-builder"
}


