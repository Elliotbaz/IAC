#!/usr/bin/env sh

set -e
export DEBIAN_FRONTEND=noninteractive

echo "${prefix}-poc" > /etc/hostname
hostnamectl set-hostname "${prefix}"

setup_log=/var/log/poc-setup.log
touch $setup_log
touch /var/log/cloud-init-output.log
echo "Starting init log." | tee -a $setup_log

echo "Installing os updates." | tee -a $setup_log
apt-get update -y

echo "Fetching instance ID." | tee -a $setup_log
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# ###################################
# # Install Docker
# ###################################
# echo "Installing Docker." | tee -a $setup_log

# echo "Installing pre-requisites." | tee -a $setup_log
# apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# echo "Adding Docker GPG key." | tee -a $setup_log
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# echo "Adding Docker repository." | tee -a $setup_log
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# echo "Updating apt package index again." | tee -a $setup_log
# apt-get update -y

# echo "Installing Docker CE (Community Edition)." | tee -a $setup_log
# apt-get install -y docker-ce

# echo "Adding user to docker group." | tee -a $setup_log
# usermod -aG docker ubuntu

# echo "Starting Docker service." | tee -a $setup_log
# systemctl start docker

# echo "Enabling Docker service." | tee -a $setup_log
# systemctl enable docker

###################################
# Install CloudWatch Agent
###################################
echo "Download the CloudWatch agent package." | tee -a $setup_log
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

echo "Install the CloudWatch agent package." | tee -a $setup_log

dpkg -i amazon-cloudwatch-agent.deb

echo "Render the CloudWatch agent configuration file." | tee -a $setup_log
cat > /tmp/cloudwatch-agent-config.json <<EOF
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
            "log_group_name": "${prefix}-poc",
            "log_stream_name": "/var/log/syslog"
          },
          {
            "file_path": "/var/log/poc-setup.log",
            "log_group_name": "${prefix}-poc",
            "log_stream_name": "/var/log/poc-setup.log"
          }
        ]
      }
    }
  }
}
EOF

echo "Copy the CloudWatch agent configuration file." | tee -a $setup_log
cp /tmp/cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "Start the CloudWatch agent." | tee -a $setup_log
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Install AWS CLI
echo "Installing AWS CLI." | tee -a $setup_log
apt-get install -y awscli

echo "Create a directory for docker projects." | tee -a $setup_log
mkdir -p /home/ubuntu/projects

##################################
# Copy docker files from s3
##################################

echo "Set ownership to the ubuntu user." | tee -a $setup_log
chown -R ubuntu:ubuntu /home/ubuntu/projects

echo "Copying docker files from s3." | tee -a $setup_log
aws s3 cp s3://${s3_bucket}/dcv-docker/ /home/ubuntu/projects/ --recursive

echo "Add execute permissions on the dcv-container-build.sh script." | tee -a $setup_log
chmod +x /home/ubuntu/projects/custom/dcv-container-build.sh

###################################
# Prepare the DCV Pre-requisites
###################################

# echo "Installing DCV pre-requisites." | tee -a $setup_log
# apt update -y

# echo "Installing Ubuntu Desktop." | tee -a $setup_log
# apt install ubuntu-desktop -y

# echo "Installing Gnome." | tee -a $setup_log
# apt upgrade -y

###################################
# # Install Nice DCV Server
###################################

# echo "Installing Nice DCV." | tee -a $setup_log

# echo "Downloading Nice DCV." | tee -a $setup_log
# wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY

# echo "Adding Nice GPG key." | tee -a $setup_log
# gpg --import NICE-GPG-KEY

# echo "Download the Nice DCV packages." | tee -a $setup_log
# wget https://d1uj6qtbmh3dt5.cloudfront.net/2023.1/Servers/nice-dcv-2023.1-16388-ubuntu2204-x86_64.tgz

# echo "Extract the Nice DCV packages." | tee -a $setup_log
# tar -xvzf nice-dcv-2023.1-16388-ubuntu2204-x86_64.tgz && cd nice-dcv-2023.1-16388-ubuntu2204-x86_64

# echo "Install the Nice DCV server." | tee -a $setup_log
# apt install ./nice-dcv-server_2023.1.16388-1_amd64.ubuntu2204.deb

# echo "Install the web client." | tee -a $setup_log
# apt install ./nice-dcv-web-viewer_2023.1.16388-1_amd64.ubuntu2204.deb

# echo "Add the dcv user to the video group." | tee -a $setup_log
# usermod -aG video dcv

# echo "Install the nicd-xdcv package for virtual sessions." | tee -a $setup_log
# apt install ./nice-xdcv_2023.1.565-1_amd64.ubuntu2204.deb -y

# echo "Install the nice-dcv-gl package for OpenGL support." | tee -a $setup_log
# apt install ./nice-dcv-gl_2023.1.1047-1_amd64.ubuntu2204.deb -y

# echo "Install the nice-dcv-simple-external-authenticator package for external authentication." | tee -a $setup_log
# apt install ./nice-dcv-simple-external-authenticator_2023.1.228-1_amd64.ubuntu2204.deb -y


###################################
# FINISHED
###################################

echo "Done." | tee -a $setup_log

