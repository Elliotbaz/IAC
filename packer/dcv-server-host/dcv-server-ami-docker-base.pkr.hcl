variable "dcv_docker_base_version" {
  type = string
  default = "1.3.3"
}

variable "dcv_docker_base_description" {
  type = string
  default = "Focal 20.04 - Host Base 1.3.3 - Updating host base. GRID driver version 16.6."
}

variable "ami_host_base_ami" {
  type = string
  default = "ami-0b534494d1960b7aa" # dcv-host-base-1.3.2-grid-16.6
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "iam_instance_profile" {
  type = string
  default = "intraverse-prod-dcv-builder-3c2cc934"
}

source "amazon-ebs" "dcv-docker-base" {
  ami_name = "dcv-docker-base-${var.dcv_docker_base_version}"
  instance_type = "g4dn.xlarge"
  region = var.region
  source_ami = var.ami_host_base_ami
  ssh_username = "ubuntu"
  iam_instance_profile = var.iam_instance_profile

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 40
    volume_type = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = var.dcv_docker_base_description
    Project = "Intraverse"
    Environment = "Production"
    ManagedBy = "Terraform"
    Owner = "jay@terrazero.com"
  }
}
build {
  sources = ["source.amazon-ebs.dcv-docker-base"]

  ###################################################
  # Provisioners
  ###################################################

  provisioner "shell" {
    execute_command = "sudo {{ .Path }}"
    script = "./userdata/init.sh"
  }

  ###################################################
  # Prepare Scripts
  ###################################################

  provisioner "shell" {
    execute_command = "sudo {{ .Path }}"
    inline = [
      "mkdir -p /opt/dcv",
      "chown -R ubuntu:ubuntu /opt/dcv"
    ]
  }

  provisioner "file" {
    source      = "./scripts/Dockerfile"
    destination = "/opt/dcv/Dockerfile"
  }

  provisioner "shell" {
    execute_command = "sudo {{ .Path }}"
    inline = [
      "chown -R ubuntu:ubuntu /opt/dcv"
    ]
  }

  ###################################################
  # Docker Setup
  ###################################################

  provisioner "shell" {
    script = "./userdata/docker-install.sh"
  }

  ###################################################
  # DCV Container Base Build
  ###################################################

  provisioner "shell" {
    script = "./userdata/dcv-container-base.sh"
  }

  ###################################################
  # Download Userdata Log
  ###################################################

  provisioner "file" {
    source      = "/var/log/userdata.log"
    destination = "userdata-docker-base-${var.dcv_docker_base_version}.log"
    direction   = "download"
  }
}