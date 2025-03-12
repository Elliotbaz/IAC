#!/bin/bash

exec &>> /var/log/startup_script.log

set -xe
# ps -ef > /tmp/ps.ef

# Check if we have a well-configured xorg.conf and create one if needed
if [ ! -f /etc/X11/xorg.conf -o "$(grep BusID /etc/X11/xorg.conf | grep PCI)" == "" ]; then
    sleep 5
    echo "Updating the X server configuration ... "
    sudo systemctl isolate multi-user.target
    sleep 1
    # dcvgladmin disable
    nvidia-xconfig --preserve-busid --enable-all-gpus --connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3
    # Add Option "HardDPMS" "false"
    sed '/^Section "Device"/a \ \ \ \ Option         "HardDPMS" "false"' /etc/X11/xorg.conf > /tmp/xorg.conf
    mv /tmp/xorg.conf /etc/X11/xorg.conf
    # sed '/^Section "Device"/a \ \ \ \ Option         "UseDisplayDevice" "none"' /etc/X11/xorg.conf > /tmp/xorg.conf
    # mv /tmp/xorg.conf /etc/X11/xorg.conf
    sleep 1
    # dcvgladmin enable
    sudo systemctl isolate graphical.target
    sleep 1
    sudo systemctl enable dcvserver 2>&1
    sudo systemctl restart dcvserver
fi

firewall-cmd --zone=public --permanent --add-port=22/tcp  # SSH standard TCP port 
firewall-cmd --zone=public --permanent --add-port=8443/tcp  # DCV standard TCP port 
firewall-cmd --zone=public --permanent --add-port=8443/udp  # In addition for UDP/QUIC
firewall-cmd --reload

# set -ex

# AWS="1"

if [ "$AWS" == "1" ]; then
    /usr/local/bin/send_dcvsessionready_notification.sh >/dev/null 2>&1 &
    export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
    export AWS_DEFAULT_REGION=${AWS_REGION}
    _username="$(aws secretsmanager get-secret-value --secret-id \
                      dcv-cred-user --query SecretString --output text)"
    _passwd="$(aws secretsmanager get-secret-value --secret-id \
                      dcv-cred-passwd --query SecretString --output text)"
else
    _username="user"
    _passwd="dcv"
fi

adduser "${_username}" -G wheel 
echo "${_username}:${_passwd}" | chpasswd
/usr/bin/dcv create-session --type=virtual --storage-root=%home% --owner "${_username}" --user "${_username}" "${_username}session"
