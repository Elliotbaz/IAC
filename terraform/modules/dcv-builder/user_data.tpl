#!/bin/bash

set -e

# Set hostname
echo "${prefix}" > /etc/hostname
hostnamectl set-hostname "${prefix}"

# Create log files
setup_log="/var/log/setup.log"
touch "$setup_log"
touch /var/log/cloud-init-output.log

echo "Starting init log." | tee -a "$setup_log"

# Install OS updates
echo "Installing OS updates." | tee -a "$setup_log"
yum update -y

# Install wget
echo "Installing wget." | tee -a "$setup_log"
yum install -y wget unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Retrieve instance ID
INSTANCE_ID=$(ec2-metadata -i | cut -d ' ' -f 2)

# Install CloudWatch Agent
echo "Installing CloudWatch Agent." | tee -a "$setup_log"
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y amazon-cloudwatch-agent.rpm

# Configure CloudWatch Agent
echo "Configure CloudWatch Agent." | tee -a "$setup_log"
cat > /tmp/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/syslog"
          },
          {
            "file_path": "/var/log/setup.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/setup.log"
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/docker.log"
          },
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/docker-container"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/cloud-init-output.log"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/cloud-init.log"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/messages"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/secure"
          },
          {
            "file_path": "/var/log/ecs/ecs-init.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/ecs/ecs-init.log"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/ecs/ecs-agent.log"
          },
          {
            "file_path": "/var/log/ecs/ecs-containerlogs.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "/var/log/ecs/ecs-containerlogs.log"
          }
        ]
      }
    }
  }
}
EOF

mv /tmp/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start CloudWatch Agent
echo "Start the CloudWatch agent." | tee -a "$setup_log"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "Downloading build scripts." | tee -a "$setup_log"
mkdir -p /opt/dcv_builder
aws s3 sync s3://${object_bucket}/${build_scripts_folder}/ /opt/dcv_builder
aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/grid-16.6/ /opt/dcv_builder
mv /opt/dcv_builder/NVIDIA-Linux-x86_64-*-grid-aws.run /opt/dcv_builder/NVIDIA-installer.run
chmod +x /opt/dcv_builder/*.sh
chmod +x /opt/dcv_builder/*.run
chown -R ec2-user:docker /opt/dcv_builder

echo "Downloading Unity Build to shared folder." | tee -a "$setup_log"
mkdir -p /mnt/shared/unity-build
aws s3 cp s3://${object_bucket}/unity-builds/unity-build-0.0.0.zip /mnt/shared
unzip /mnt/shared/unity-build-0.0.0.zip -d /mnt/shared/unity-build
chown ec2-user:docker -R /mnt/shared
chmod 755 -R /mnt/shared/unity-build

echo "Done." | tee -a "$setup_log"