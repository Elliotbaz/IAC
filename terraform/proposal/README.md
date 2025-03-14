# TerraZero Render Streaming Service

## Network

### VPC, Subnets, Routes, Gateways

[Terraform Registry - VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

> NOTE: Be careful when considering your CIDR block. You may want to peer some of these VPCs at some point and you can't peer two VPCs that are using the same CIDR.

#### Usage
```hcl
provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "ex-${basename(path.cwd)}"
  region = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "../../"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]

  tags = local.tags
}
```