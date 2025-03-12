resource "aws_launch_template" "dcv_server" {
  name_prefix   = "dcv-server-"
  # image_id      = "ami-0deeeb5864a581806"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    subnet_id                   = var.subnet_id
    security_groups             = [var.security_group_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(<<-USERDATA
#! /bin/bash

set -e

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> /var/log/userdata.log
    # echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

log "================================================"
log "Starting the user data script"
log "================================================"

log "Installing CloudWatch Agent"
if ! apt install -y amazon-cloudwatch-agent; then
    log "Failed to install CloudWatch Agent"
    exit 1
fi

log "Create the CloudWatch Agent configuration file"
cat << CLOUDWATCH | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/cloud-init-output.log",
                        "log_group_name": "intraverse-dev-dcv-builder",
                        "log_stream_name": "{instance_id}/cloud-init-output",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S",
                        "multi_line_start_pattern": "^\\d{4}-\\d{2}-\\d{2}"
                    },
                    {
                        "file_path": "/var/log/cloud-init.log",
                        "log_group_name": "intraverse-dev-dcv-builder",
                        "log_stream_name": "{instance_id}/cloud-init",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S",
                        "multi_line_start_pattern": "^\\d{4}-\\d{2}-\\d{2}"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "intraverse-dev-dcv-builder",
                        "log_stream_name": "{instance_id}/user-data",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S",
                        "multi_line_start_pattern": "^\\d{4}-\\d{2}-\\d{2}"
                    }
                ]
            }
        }
    }
}
CLOUDWATCH

log "Starting the CloudWatch Agent"
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent


log "Running the containers (commented out for now)"
# sudo /usr/local/bin/cm-containers-run.sh --port 8080
# sudo /usr/local/bin/cm-containers-run.sh --port 8081

log "================================================"
log "Finished the user data script"
log "================================================"

USERDATA
  )

  # Tags are not directly supported in launch templates but can be added to instances created by autoscaling groups
}

resource "aws_autoscaling_group" "dcv_server_asg" {
  name_prefix         = "dcv-server-asg-"
  min_size            = 0
  max_size            = 4  # Adjust based on your scaling needs
  desired_capacity    = 1
  vpc_zone_identifier = [var.subnet_id]  # Use the same subnet as in the launch template

  launch_template {
    id      = aws_launch_template.dcv_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dcv-server-host-${var.ami_hash}-intraverse-${var.game_version}"
    propagate_at_launch = true
  }

  tag {
    key                 = "ami-id"
    value               = var.ami_id
    propagate_at_launch = true
  }

  tag {
    key                 = "ami-hash"
    value               = var.ami_hash
    propagate_at_launch = true
  }

  tag {
    key                 = "intraverse-version"
    value               = var.game_version
    propagate_at_launch = true
  }

  tag {
    key                 = "Stage"
    value               = "dev"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "dcv-cm-api"
    propagate_at_launch = true
  }

  tag {
    key                 = "ports"
    value               = "[{\"8080\":\"available\"},{\"8081\":\"available\"}]"
    propagate_at_launch = true
  }

  tag {
    key                 = "port-8080"
    value               = "available"
    propagate_at_launch = true
  }

  tag {
    key                 = "port-8081"
    value               = "available"
    propagate_at_launch = true
  }
}