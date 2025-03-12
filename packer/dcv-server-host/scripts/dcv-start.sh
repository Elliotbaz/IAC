#!/bin/bash

exec &>> /var/log/startup_script.log

set -xe
# ps -ef > /tmp/ps.ef

# Check if we have a well configured xorg.conf and create one in case
if [ ! -f /etc/X11/xorg.conf -o "`grep BusID /etc/X11/xorg.conf | grep PCI`" == "" ] ; then
    sleep 5
    echo "Updating the X server configuration ... "
    sudo systemctl isolate multi-user.target
    sleep 1
    # dcvgladmin disable
    nvidia-xconfig --preserve-busid --enable-all-gpus --connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3
    # add  Option         "HardDPMS" "false"
    sed '/^Section "Device"/a \ \ \ \ Option         "HardDPMS" "false"'  /etc/X11/xorg.conf > /tmp/xorg.conf
    mv /tmp/xorg.conf /etc/X11/xorg.conf
    sed '/^Section "Device"/a \ \ \ \ Option         "UseDisplayDevice" "none"'  /etc/X11/xorg.conf > /tmp/xorg.conf
    # mv /tmp/xorg.conf /etc/X11/xorg.conf
    sleep 1
    # dcvgladmin enable
    sudo systemctl isolate graphical.target
    sleep 1
    sudo systemctl enable dcvserver 2>&1
    sudo systemctl restart dcvserver
fi

# AWS="1"


_username="user"
_passwd="dcv"

adduser "${_username}"
echo "${_username}:${_passwd}" |chpasswd

# If a user already exists, disable the Welcome wizard for that user too
if id "user" &>/dev/null; then \
    mkdir -p /home/user/.config && \
    echo "[org.gnome.shell]" > /home/user/.config/gnome-initial-setup-done && \
    echo "welcome-dialog-last-shown-version='999999'" >> /home/user/.config/gnome-initial-setup-done && \
    chown -R user:user /home/user/.config; \
fi

# /usr/bin/dcv create-session --type=virtual --storage-root=%home% --owner "user" --user "user" "usersession"
# /usr/bin/dcv create-session --init=/var/lib/dcv/init.sh --type=virtual --storage-root=%home% --owner "user" --user "user" "usersession"
/usr/bin/dcv create-session --init=/var/lib/dcv/init.sh --type=virtual --storage-root=%home% --owner "${_username}" --user "${_username}" "${_username}session"

# /usr/local/bin/run_game.sh
