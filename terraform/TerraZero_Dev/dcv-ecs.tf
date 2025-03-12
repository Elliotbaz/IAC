# ecr
resource "aws_ecr_repository" "dcv" {
  name = "${local.prefix}-dcv"
}

# # bastion server
# resource "aws_instance" "dcv-bastion" {
  
#   ami = "ami-066784287e358dad1"
#   instance_type = "t2.micro"
#   key_name = local.ssh_key_name
#   subnet_id = module.vpc.public_subnets[0]
#   vpc_security_group_ids = [aws_security_group.dcv-bastion.id]
#   tags = merge(local.common_tags, {
#     Name = "${local.prefix}-dcv-bastion"
#   })
# }
  

# security group
resource "aws_security_group" "dcv-bastion" {
  name = "${local.prefix}-dcv-bastion"
  vpc_id = module.vpc.vpc_id
  tags = local.common_tags
}

resource "aws_security_group_rule" "dcv-bastion-ssh-ingress" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.dcv-bastion.id
  cidr_blocks = ["0.0.0.0/0"]
}

# use the dcv server security grouip id output to create an ingress rule for the bastion
resource "aws_security_group_rule" "dcv-bastion-dcv-ingress" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = module.ecs.dcv_server_security_group_id
  source_security_group_id = aws_security_group.dcv-bastion.id
}

module "ecs" {
  # source = "git::https://github.com/TerrazeroOrg/iac.git//terraform/modules/dcv-ecs"
  source = "../modules/dcv-ecs"
  
  tags = local.common_tags
  prefix = local.prefix
  environment = local.environment
  dcv_ecr_url = aws_ecr_repository.dcv.repository_url
  vpc_id = module.vpc.vpc_id
  dcv_server_listener_id = module.alb.dcv_server_listener_id
  https_listener_id = module.alb.https_listener_id
  domain = local.domain
  ssh_key_name = local.ssh_key_name
  instance_type = local.dcv_server_instance_type
  ami_id = local.dcv_server_ami_id
  alb_sg_id = module.alb.security_group_id
  # deploy_compute = local.deploy_compute
  deploy_compute = false
  private_subnets = module.vpc.private_subnets
  object_bucket = aws_s3_bucket.builder-objects.bucket
}
