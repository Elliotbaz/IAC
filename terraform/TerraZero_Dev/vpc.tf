module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.9.0"
    name = "${local.prefix}"
    cidr = "10.1.0.0/16" # this cidr block should vary from env to env so we have the option to set up peering if we need to
    azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"] # adjust these subnets according to the cidr block
    public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
}
