terraform {
  backend "s3" {
    bucket = "intraverse-dev-terraform-state-0b50c4893db71531"
    key    = "examples/dcv-server-builder2.tfstate"
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
    environment = "Example"
    region = "us-east-1"
    prefix = lower("${local.project}-example2")
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
}


module "dcv-builder" {
#   source = "git::https://github.com/TerrazeroOrg/iac.git//terraform/modules/dcv-builder?ref=v1.0.30"
    source = "../../modules/dcv-builder"

    tags = local.common_tags
    prefix = local.prefix
    environment = local.environment
    deploy_builder = local.deploy_builder
    instance_type = local.dcv_server_instance_type
    ami_id = local.dcv_server_ami_id
    ssh_key_name = local.ssh_key_name
    public_subnets = ["subnet-0c5e5f6b346f46246", "subnet-0371d8db1f358320f", "subnet-092585e9413017b87"]
    vpc_id = "vpc-0ceb30d8b25ce3ed7"
    object_bucket = "intraverse-dev-builder-objects-18f71b13"
}

resource "aws_instance" "builder" {
    ami = local.dcv_server_ami_id
    instance_type = local.dcv_server_instance_type
    key_name = local.ssh_key_name
    subnet_id = "subnet-0c5e5f6b346f46246"
    iam_instance_profile = module.dcv-builder.iam_instance_profile_name
    launch_template {
        id = module.dcv-builder.launch_template_id
        version = "$Latest"
    }
    tags = merge(local.common_tags, {
        Name = "${local.prefix}-dcv-builder"
    })
}