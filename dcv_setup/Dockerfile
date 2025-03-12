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
RUN wget -q http://us.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run -O /tmp/NVIDIA-installer.run && \
    bash /tmp/NVIDIA-installer.run --accept-license \
    --install-libglvnd \
    --no-questions --no-kernel-module-source \
    --no-nvidia-modprobe --no-kernel-module \
    --disable-nouveau \
    --no-backup \
    --ui=none || (cat /var/log/nvidia-installer.log && exit 1) && \
    rm -f /tmp/NVIDIA-installer.run && \
    nvidia-xconfig --preserve-busid --enable-all-gpus -connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3

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

# Set permissions
RUN chmod +x /usr/local/bin/run_script.sh \
    /usr/local/bin/send_dcvsessionready_notification.sh \
    /usr/local/bin/startup_script.sh

EXPOSE 8443

CMD ["/usr/local/bin/run_script.sh"]