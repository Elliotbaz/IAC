module "dcv-builder" {
  source = "git::https://github.com/TerrazeroOrg/iac.git//terraform/modules/dcv-builder?ref=v1.0.34"

    tags = local.common_tags
    prefix = local.prefix
    environment = local.environment
    deploy_builder = local.deploy_builder
    instance_type = local.dcv_server_instance_type
    ami_id = local.dcv_server_ami_id
    ssh_key_name = local.ssh_key_name
    public_subnets = module.vpc.public_subnets
    vpc_id = module.vpc.vpc_id
    object_bucket = aws_s3_bucket.builder-objects.bucket
}

# s3 bucket for dcv builder scripts
resource "aws_s3_bucket" "builder-objects" {
  bucket = "${local.prefix}-builder-objects-${local.suffix}"
}