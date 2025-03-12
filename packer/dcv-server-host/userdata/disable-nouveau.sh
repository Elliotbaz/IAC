#!/bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Disabling the nouveau driver START"
log "============================================"

log "Disabling the nouveau driver"

cat << EOF | tee --append /etc/modprobe.d/blacklist.conf
blacklist nouveau
options nouveau modeset=0
EOF
echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | tee -a /etc/default/grub > /dev/null
if ! update-grub; then
    log "Failed to update GRUB"
    exit 1
fi

log "Rebooting ..."
if ! reboot; then
    log "Failed to reboot"
    exit 1
fi
