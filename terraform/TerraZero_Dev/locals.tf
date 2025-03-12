resource "random_id" "suffix" {
  byte_length = 4
}

locals {
    project = "Intraverse"
    environment = "Development"
    region = "us-east-1"
    suffix      = random_id.suffix.hex
    prefix = lower("${local.project}-dev")
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
    deploy_compute = true
    deploy_builder = false
}
