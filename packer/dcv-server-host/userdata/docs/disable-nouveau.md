# Disabling Nouveau

This script, `disable-nouveau.sh`, is designed to disable the Nouveau open-source graphics driver on an Ubuntu-based system. Here's a brief explanation of what it's doing and why:

### What the Script Does:

1. **Logging Setup**:
   - Functions like `log` are defined to echo messages with color coding and log them to `/var/log/userdata.log`.

2. **Blacklisting Nouveau Driver**:
   - It appends entries to `/etc/modprobe.d/blacklist.conf` to blacklist the `nouveau` driver and set `modeset=0` to prevent it from starting.

3. **GRUB Configuration**:
   - Adds `rdblacklist=nouveau` to the GRUB_CMDLINE_LINUX in `/etc/default/grub`. This ensures that the nouveau driver is blacklisted even before the initramfs is loaded.

4. **Update GRUB**:
   - Runs `update-grub` (likely `update-grub2` on newer systems) to update the GRUB configuration file.

5. **Reboot**:
   - Initiates a system reboot, which is necessary for the changes to take effect.

### Why This is Done:

- **Compatibility and Performance**: Many users disable the Nouveau driver because it might not offer the same level of performance, features, or stability as NVIDIA's proprietary drivers, especially for gaming or professional graphics tasks.

- **Installation of NVIDIA Drivers**: Before installing NVIDIA's proprietary drivers, it's common practice to disable Nouveau to prevent conflicts. Both drivers can't run simultaneously, and Nouveau might load first if not blacklisted.

- **Troubleshooting**: Sometimes, Nouveau can cause issues with certain hardware or software configurations. Disabling it can resolve these issues.

### Key Points:

- **Blacklisting**: By blacklisting in `/etc/modprobe.d/blacklist.conf`, the system won't load the driver at boot. 
- **GRUB Changes**: Modifying GRUB's command line ensures the driver is blacklisted early in the boot process, before the kernel loads.
- **Reboot**: Changes to kernel modules or boot parameters typically require a reboot to apply.

### Considerations:

- **NVIDIA Driver Installation**: After running this script and rebooting, you'd typically install the NVIDIA drivers using `sudo apt install nvidia-driver-<version>` or similar, depending on your Ubuntu version and hardware.
- **Testing**: It's advisable to test your system after disabling Nouveau but before installing the NVIDIA drivers to ensure no immediate issues arise from the absence of a graphics driver.

This script ensures a clean environment for installing proprietary NVIDIA drivers, addressing common conflicts, and enhancing system stability or performance for NVIDIA hardware users.

### userdata/disable-nouveau.sh
```bash
#!/bin/bash

set -e
set -x

function log {
    echo -e "${GREEN}$1${NC}" | tee -a /var/log/userdata.log
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

log "============================================"
log "Disabling the nouveau driver END"
log "============================================"
```