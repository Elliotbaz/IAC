packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "instance_type" {
  type = string
  default = "g4dn.xlarge"
}

variable "iam_instance_profile" {
  type = string
  default = "intraverse-prod-dcv-builder-3c2cc934"
}

variable "dcv_version" {
  type = string
  default = "1.3.11"
}

variable "game_version" {
  type = string
  default = "1.3.6"
} 

variable "game_build_bucket" {
  type = string
  default = "intraverse-prod-dcv-builder-3c2cc934"
}

variable "game_build_folder" {
  type = string
  default = "unity-builds"
}

# variable "instance_type" {
#   type = string
#   default = "g4dn.xlarge"
# }

# variable "region" {
#   type = string
#   default = "us-east-1"
# }


variable "dcv_docker_base_ami" {
  type = string
  default = "ami-0f43a6fad5c795baf"
}

# variable "iam_instance_profile" {
#   type = string
#   default = "intraverse-prod-dcv-builder-3c2cc934"
# }

source "amazon-ebs" "dcv-final" {
  ami_name = "dcv-server-${var.dcv_version}-intraverse-${var.game_version}"
  instance_type = var.instance_type
  region = var.region
  source_ami = var.dcv_docker_base_ami
  ssh_username = "ubuntu"
  iam_instance_profile = var.iam_instance_profile

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 40
    volume_type = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = "dcv-server-${var.dcv_version}-intraverse-${var.game_version}"
    Project = "Intraverse"
    Environment = "Production"
    ManagedBy = "Packer"
    Owner = "jay@terrazero.com"
  }
}
build {
  sources = ["source.amazon-ebs.dcv-final"]

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
    source      = "./scripts/dcv-build.sh"
    destination = "/opt/dcv/dcv-build.sh"
  }

  provisioner "file" {
    source      = "./scripts/dcv-run.sh"
    destination = "/opt/dcv/dcv-run.sh"
  }

  provisioner "file" {
    source      = "./scripts/dcv-start.sh"
    destination = "/opt/dcv/dcv-start.sh"
  }

  provisioner "file" {
    source      = "./scripts/dcv-launch-game.sh"
    destination = "/opt/dcv/dcv-launch-game.sh"
  }

  provisioner "file" {
    source      = "./scripts/dcv-init.sh"
    destination = "/opt/dcv/dcv-init.sh"
  }

  provisioner "file" {
    source      = "./scripts/dcv.conf"
    destination = "/opt/dcv/dcv.conf"
  }

  provisioner "file" {
    source      = "./scripts/dcvserver.service"
    destination = "/opt/dcv/dcvserver.service"
  }

  provisioner "file" {
    source      = "./scripts/Dockerfile.dcv"
    destination = "/opt/dcv/Dockerfile.dcv"
  }

  provisioner "file" {
    source      = "./scripts/cm-exec-cmd.sh"
    destination = "/home/ubuntu/cm-exec-cmd.sh"
  }

  provisioner "file" {
    source      = "./scripts/cm-prepare-env.sh"
    destination = "/home/ubuntu/cm-prepare-env.sh"
  }

  provisioner "file" {
    source      = "./scripts/cm-clear-env.sh"
    destination = "/home/ubuntu/cm-clear-env.sh"
  }

  provisioner "file" {
    source      = "./scripts/cm-update-tags.sh"
    destination = "/home/ubuntu/cm-update-tags.sh"
  }

  provisioner "file" {
    source      = "./scripts/cm-containers-run.sh"
    destination = "/home/ubuntu/cm-containers-run.sh"
  }

  provisioner "file" {
    source      = "./scripts/cm-containers-stop.sh"
    destination = "/home/ubuntu/cm-containers-stop.sh"
  }

  provisioner "file" {
    source      = "./scripts/cm-setup-displays.sh"
    destination = "/home/ubuntu/cm-setup-displays.sh"
  }

  provisioner "shell" {
    execute_command = "sudo {{ .Path }}"
    inline = [
      "chmod +x /home/ubuntu/cm-exec-cmd.sh && mv /home/ubuntu/cm-exec-cmd.sh /usr/local/bin/cm-exec-cmd.sh",
      "chmod +x /home/ubuntu/cm-prepare-env.sh && mv /home/ubuntu/cm-prepare-env.sh /usr/local/bin/cm-prepare-env.sh",
      "chmod +x /home/ubuntu/cm-clear-env.sh && mv /home/ubuntu/cm-clear-env.sh /usr/local/bin/cm-clear-env.sh",
      "chmod +x /home/ubuntu/cm-update-tags.sh && mv /home/ubuntu/cm-update-tags.sh /usr/local/bin/cm-update-tags.sh",
      "chmod +x /home/ubuntu/cm-containers-run.sh && mv /home/ubuntu/cm-containers-run.sh /usr/local/bin/cm-containers-run.sh",
      "chmod +x /home/ubuntu/cm-containers-stop.sh && mv /home/ubuntu/cm-containers-stop.sh /usr/local/bin/cm-containers-stop.sh",
      "chmod +x /home/ubuntu/cm-setup-displays.sh && mv /home/ubuntu/cm-setup-displays.sh /usr/local/bin/cm-setup-displays.sh",
      "chmod +x /opt/dcv/dcv-build.sh",
      "chmod +x /opt/dcv/dcv-run.sh",
      "chmod +x /opt/dcv/dcv-start.sh",
      "chmod +x /opt/dcv/dcv-launch-game.sh",
      "chmod +x /opt/dcv/dcv-init.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "sudo {{ .Path }}"
    inline = [
      "chown -R ubuntu:ubuntu /opt/dcv"
    ]
  }

  ###################################################
  # Download Game Build
  ###################################################

  provisioner "shell" {
    environment_vars = [
      "UNITY_BUILD_VERSION=${var.game_version}",
      "UNITY_BUILD_BUCKET=${var.game_build_bucket}",
      "UNITY_BUILD_PATH=${var.game_build_folder}"
    ]
    script = "./userdata/game-build-download.sh"
  }

  ###################################################
  # DCV Container Build
  ###################################################

  provisioner "shell" {
    script = "./userdata/dcv-container-final.sh"
  }

  ###################################################
  # Download Userdata Log
  ###################################################

  provisioner "file" {
    source      = "/var/log/userdata.log"
    destination = "userdata-${var.dcv_version}.log"
    direction   = "download"
  }
}