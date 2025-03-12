variable "instance_type" {
  type = string
  default = "g4dn.xlarge"
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "iam_instance_profile" {
  type = string
  default = "intraverse-prod-dcv-builder-3c2cc934"
}

variable "dcv_host_base_version" {
  type = string
  default = "1.3.2"
}

variable "dcv_host_base_description" {
  type = string
  default = "Focal 20.04 - Base image for the host build. Locks in the GRID driver version."
}

variable "ubuntu_base_ami" {
  type = string
  default = "ami-0f7820c567ed7e06e" # ubuntu 20.04 base ami
}

variable "grid_driver_version" {
  type = string
  default = "grid-16.6"
}

source "amazon-ebs" "dcv-host-base" {
  ami_name = "dcv-host-base-${var.dcv_host_base_version}-${var.grid_driver_version}"
  instance_type = var.instance_type
  region = var.region
  source_ami = var.ubuntu_base_ami
  ssh_username = "ubuntu"
  iam_instance_profile = var.iam_instance_profile

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 40
    volume_type = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = var.dcv_host_base_description
    Project = "Intraverse"
    Environment = "Development"
    ManagedBy = "Terraform"
    Stage = "host-base"
    Owner = "jay@terrazero.com"
  }
}
build {
  sources = ["source.amazon-ebs.dcv-host-base"]

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
  # Nvidia Driver Setup
  ###################################################

  provisioner "shell" {
    execute_command = "sudo {{ .Path }}"
    script = "./userdata/disable-nouveau.sh"
    expect_disconnect = true
  }

  # These are split up on the reboot, otherwise I would have combined them.
  provisioner "shell" {
    environment_vars = [
      "GRID_DRIVER_VERSION=${var.grid_driver_version}"
    ]
    script = "./userdata/nvidia-driver-install.sh"
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
    destination = "userdata-host-base-${var.dcv_host_base_version}.log"
    direction   = "download"
  }
}