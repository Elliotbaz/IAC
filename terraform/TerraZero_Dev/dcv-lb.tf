# dcv-lb.tf

module "alb" {
  source = "../modules/dcv-lb"
  project = local.project
  environment = local.environment
  region = local.region
  tags = local.common_tags
  prefix = local.prefix
  suffix = local.suffix
  vpc_id = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  certificate_arn = local.certificate_arn
}