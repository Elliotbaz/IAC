terraform {
  backend "s3" {
    bucket = "intraverse-dev-terraform-state-0b50c4893db71531"
    key    = "utilities/bastion.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

locals {
    project = "Intraverse"
    environment = "Utilities"
    region = "us-east-1"
    prefix = lower("${local.project}-util")
    suffix = "18f71b13"
    vpc_id = "vpc-0ceb30d8b25ce3ed7"
    public_subnets = ["subnet-0c5e5f6b346f46246", "subnet-0371d8db1f358320f", "subnet-092585e9413017b87"]
    certificate_arn = "arn:aws:acm:us-east-1:585415957264:certificate/f00cc958-e460-4498-8f4a-5d508a4e8221"
    domain = "intraversedev.com"
    ssh_key_name = "intraverse-development-dcv-server"
    dcv_server_instance_type = "g4dn.xlarge"
    dcv_server_ami_id = "ami-060b0c7c068688ad1" #unofficial-amzn2-ami-ecs-gpu-hvm-2.0.20240725-x86_64-ebs (ECS Optimized with Nvidia 535.183.01 GPU drivers)
    common_tags = {
        Project     = local.project
        Environment = local.environment
        ManagedBy   = "Terraform"
        Owner       = "jay@terrazero.com"
    }
    deploy_compute = false
    deploy_builder = false
    dcv_server_instance_sg = "sg-037d7123ccd862c41"
    dcv_server_alb_sg = "sg-0c64a9168c3ec378d"
    dcv_server_alb_arn = "arn:aws:elasticloadbalancing:us-east-1:585415957264:loadbalancer/app/intraverse-dev-dcv-18f71b13/3dd6471f8bfd4260"
}