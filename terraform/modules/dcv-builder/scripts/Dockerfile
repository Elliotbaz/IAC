FROM ubuntu:20.04
USER root
ARG DEBIAN_FRONTEND=noninteractive
ENV container=docker
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Install tools
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    tar vim wget kmod software-properties-common apt-transport-https \
    sudo pciutils ca-certificates xz-utils locales curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install X Server, Gnome and GL libs/dependencies
RUN apt-get update && apt-get install -y \
    mesa-utils libxvmc-dev libxatracker-dev \
    xserver-xorg-core xserver-xorg xserver-xorg-dev xorg x11-utils xauth xinit \
    openbox xfonts-base xterm freeglut3 ubuntu-desktop-minimal gnome-shell gdm3 \
    libglfw3-dev libgles2-mesa-dev libglew-dev glew-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Nvidia Driver
ADD NVIDIA-installer.run /tmp/NVIDIA-installer.run
RUN  bash /tmp/NVIDIA-installer.run --accept-license \
        --install-libglvnd \
    --no-questions --no-kernel-module-source \
        --no-nvidia-modprobe --no-kernel-module \
        --disable-nouveau \
    --no-backup \
    --ui=none || (cat /var/log/nvidia-installer.log && exit 1) && \
    rm -f /tmp/NVIDIA-installer.run \
    && nvidia-xconfig --preserve-busid --enable-all-gpus -connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3

# RUN wget -q http://us.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run -O /tmp/NVIDIA-installer.run && \
#     bash /tmp/NVIDIA-installer.run --accept-license \
#     --install-libglvnd \
#     --no-questions --no-kernel-module-source \
#     --no-nvidia-modprobe --no-kernel-module \
#     --disable-nouveau \
#     --no-backup \
#     --ui=none || (cat /var/log/nvidia-installer.log && exit 1) && \
#     rm -f /tmp/NVIDIA-installer.run && \
#     nvidia-xconfig --preserve-busid --enable-all-gpus -connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3

# Install NICE DCV
RUN mkdir -p /tmp/dcv-inst && \
    cd /tmp/dcv-inst && \
    wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY && \
    gpg --import NICE-GPG-KEY && \
    wget https://d1uj6qtbmh3dt5.cloudfront.net/2022.2/Servers/nice-dcv-2022.2-13907-ubuntu2004-x86_64.tgz && \
    tar -xvzf nice-dcv-2022.2-13907-ubuntu2004-x86_64.tgz && \
    cd nice-dcv-2022.2-13907-ubuntu2004-x86_64 && \
    apt-get update && \
    apt-get install -y \
    ./nice-dcv-server_2022.2.13907-1_amd64.ubuntu2004.deb \
    ./nice-dcv-web-viewer_2022.2.13907-1_amd64.ubuntu2004.deb \
    ./nice-xdcv_2022.2.481-1_amd64.ubuntu2004.deb \
    ./nice-dcv-gl_2022.2.983-1_amd64.ubuntu2004.deb \
    ./nice-dcv-simple-external-authenticator_2022.2.198-1_amd64.ubuntu2004.deb && \
    usermod -aG video dcv && \
    rm -rf /tmp/dcv-inst && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy necessary files
COPY dcvserver.service /usr/lib/systemd/system/dcvserver.service
COPY send_dcvsessionready_notification.sh /usr/local/bin/
COPY startup_script.sh /usr/local/bin/
COPY run_script.sh /usr/local/bin/
COPY dcv.conf /etc/dcv/
COPY run_game.sh /usr/local/bin/

COPY unity-build.zip /var/lib/dcv/Desktop/unity-build.zip
RUN unzip /var/lib/dcv/Desktop/unity-build.zip -d /var/lib/dcv/Desktop && \
    rm /var/lib/dcv/Desktop/unity-build.zip

# Set permissions
RUN chmod +x /usr/local/bin/run_script.sh \
    /usr/local/bin/send_dcvsessionready_notification.sh \
    /usr/local/bin/startup_script.sh \
    /usr/local/bin/run_game.sh \
    /var/lib/dcv/Desktop/IntraverseClient.x86_64

RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get autoremove -y && apt-get clean
# Disable update notifications
RUN echo 'APT::Periodic::Update-Package-Lists "0";' >> /etc/apt/apt.conf.d/10periodic && \
    echo 'APT::Periodic::Unattended-Upgrade "0";' >> /etc/apt/apt.conf.d/10periodic && \
    echo 'APT::Periodic::Download-Upgradeable-Packages "0";' >> /etc/apt/apt.conf.d/10periodic && \
    echo 'APT::Periodic::AutocleanInterval "0";' >> /etc/apt/apt.conf.d/10periodic

RUN sed -i 's/^#\?WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf && \
    echo 'AutomaticLoginEnable=true' >> /etc/gdm3/custom.conf && \
    echo 'AutomaticLogin=user' >> /etc/gdm3/custom.conf

RUN apt-get install -y gnome-session gnome-terminal && \
    echo "export XDG_CURRENT_DESKTOP=ubuntu:GNOME" >> /etc/profile && \
    echo "export GNOME_SHELL_SESSION_MODE=ubuntu" >> /etc/profile && \
    echo "export XDG_SESSION_TYPE=x11" >> /etc/profile && \
    echo "export XDG_SESSION_DESKTOP=ubuntu" >> /etc/profile && \
    echo "export XDG_GREETER_SESSION=lightdm-gtk-greeter" >> /etc/profile && \
    echo "export DESKTOP_SESSION=ubuntu" >> /etc/profile && \
    echo "export GDMSESSION=ubuntu" >> /etc/profile && \
    echo "gsettings set com.ubuntu.desktop.welcome show-welcome false" >> /etc/profile && \
    echo "gsettings set com.ubuntu.update-notifier no-show-notifications true" >> /etc/profile && \
    echo "gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0" >> /etc/profile

RUN gsettings set org.gnome.desktop.lockdown disable-lock-screen true && \
    gsettings set org.gnome.desktop.session idle-delay 0 && \
    gsettings set com.ubuntu.update-notifier no-show-notifications true && \
    gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0

# Disable update-notifier
RUN apt-get remove -y update-notifier update-notifier-common && \
    apt-get autoremove -y

RUN gsettings set org.gnome.desktop.lockdown disable-lock-screen true && \
    gsettings set org.gnome.desktop.session idle-delay 0

# Disable lock screen and screensaver
RUN mkdir -p /etc/dconf/db/local.d && \
    echo "[org/gnome/desktop/lockdown]" > /etc/dconf/db/local.d/00-disable-lock-screen && \
    echo "disable-lock-screen=true" >> /etc/dconf/db/local.d/00-disable-lock-screen && \
    echo "[org/gnome/desktop/screensaver]" >> /etc/dconf/db/local.d/00-disable-lock-screen && \
    echo "lock-enabled=false" >> /etc/dconf/db/local.d/00-disable-lock-screen && \
    echo "[org/gnome/desktop/session]" >> /etc/dconf/db/local.d/00-disable-lock-screen && \
    echo "idle-delay=uint32 0" >> /etc/dconf/db/local.d/00-disable-lock-screen && \
    dconf update

# Ensure the settings are applied system-wide
RUN mkdir -p /etc/dconf/profile && \
    echo "user-db:user" > /etc/dconf/profile/user && \
    echo "system-db:local" >> /etc/dconf/profile/user

# Update existing gsettings commands
RUN gsettings set org.gnome.desktop.lockdown disable-lock-screen true && \
    gsettings set org.gnome.desktop.screensaver lock-enabled false && \
    gsettings set org.gnome.desktop.session idle-delay 0

# Ensure automatic login is still configured
RUN sed -i 's/^#\?WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf && \
    echo '[daemon]' >> /etc/gdm3/custom.conf && \
    echo 'AutomaticLoginEnable=true' >> /etc/gdm3/custom.conf && \
    echo 'AutomaticLogin=user' >> /etc/gdm3/custom.conf
    
# Disable the Welcome wizard for all users
RUN mkdir -p /etc/skel/.config
RUN echo "[org.gnome.shell]" > /etc/skel/.config/gnome-initial-setup-done && \
    echo "welcome-dialog-last-shown-version='999999'" >> /etc/skel/.config/gnome-initial-setup-done

EXPOSE 8443

CMD ["/usr/local/bin/run_script.sh"]