#!/bin/bash

target="dcv-ubuntu20.04-gpu"

RED='\033[0;31m'; GREEN='\033[0;32m'; GREY='\033[0;37m'; BLUE='\034[0;37m'; NC='\033[0m' 
ORANGE='\033[0;33m'; BLUE='\033[0;34m';

echo -e "${GREEN}###################################################"
echo -e "NICE DCV for Container Installation starting"
echo -e "  created by NI SP GmbH                         " 
echo -e "  https://www.ni-sp.com/contact/              " 
echo -e "###################################################${NC}"
echo
sleep 1.5

# Set the default port
port=${1:-8443}  # Default to 8443 if no argument is passed
external_port=${2:-8080}  # Default external port to 8080 if no argument is passed

# Check OS and NVIDIA driver
[ -f /etc/os-release ] && . /etc/os-release
if [ -f /etc/redhat-release -o "$ID" == "ubuntu" -o "$ID" == "amzn" ] ; then
    :
else
    if [ -f /usr/bin/nvidia-smi ] ; then
        :   # we seem to be good 
    else
        echo -e "${RED}##########################################"
        echo -e "Please install the nVidia driver first with the same version as in the Dockerfile"
        echo -e "At the moment we support only Redhat/Centos or Ubuntu nvidia driver installation on the host as part of this script"
        echo -e "##########################################${NC}"
        exit 1
    fi
fi    

# Check if on AWS
ip=$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4 | grep \.)
onaws=$([ -n "$ip" ] && echo "1" || echo "0")

# Install nVidia driver on host if not present
if ! nvidia-smi &>/dev/null; then
    echo -e "${GREEN}##########################################"
    echo -e "Starting nVidia driver installation "
    echo -e "##########################################${NC}"
    sleep 0.75
    
    # Disable nouveau driver if necessary
    if ! grep -q "blacklist nouveau" /etc/modprobe.d/blacklist.conf 2>/dev/null; then
        echo 
        read -p "We will first disable the nouveau driver and reboot the server. Is this ok? (y/n) " answer
        if [[ $answer =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}##########################################"
            echo -e "Disabling the nouveau driver"
            echo -e "##########################################${NC}"
            sudo tee -a /etc/modprobe.d/blacklist.conf << EOF
blacklist nouveau
options nouveau modeset=0
EOF
            echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub > /dev/null
            if [ "$ID" == "ubuntu" ]; then
                sudo update-grub
            else
                sudo yum update -y
                sudo grub2-mkconfig -o /boot/grub2/grub.cfg
            fi
            echo 
            echo "Rebooting ..."
            echo -e "${GREEN}##########################################"
            echo "Please relogin to your server and restart "
            echo "   the build script $0 "
            echo "   to continue the installation." 
            echo -e "##########################################${NC}"
            sudo reboot
        else
            echo "Exiting ..."
            exit 1
        fi
    else
        echo -e "${GREEN}"
        echo "Nouveau driver is disabled - continuing ..."
        echo -e "${NC}"
    fi

    # Install nVidia driver
    echo -e "${GREEN}##########################################"
    echo "Installing nVidia driver on the host"
    echo -e "##########################################${NC}"
    sleep 1
    
    if [ "$ID" == "ubuntu" ]; then
        sudo apt-get update -y
        sudo apt-get install -y gcc make linux-headers-$(uname -r)
        if [ "$onaws" == "0" ]; then 
            wget -q http://us.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run -O /tmp/NVIDIA-installer.run
        else
            sudo apt install -y awscli
            aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/latest/ .
            mv ./NVIDIA-Linux-x86_64*.run /tmp/NVIDIA-installer.run
        fi
    else
        if [ "$ID" == "amzn" ]; then
            sudo yum install -y gcc kernel-devel-$(uname -r) 
        else
            sudo yum -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
            if [ "$ID$VERSION_ID" == "centos7" ]; then
                sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
            else
                sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
            fi
        fi
        sudo yum -y install dkms wget vim
        if [ "$onaws" == "0" ]; then 
            wget -q http://us.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run -O /tmp/NVIDIA-installer.run
        else
            sudo yum install python3-pip -y
            pip3 install awscli --upgrade --user
            aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/latest/ .
            mv ./NVIDIA-Linux-x86_64*.run /tmp/NVIDIA-installer.run && chmod o+x /tmp/NVIDIA-installer.run
        fi
    fi
    
    if [ "$ID" == "amzn" ] && [[ $(uname -r) =~ 5.10 ]]; then
        sudo CC=/usr/bin/gcc10-cc /tmp/NVIDIA-installer.run --accept-license --no-questions --no-backup --ui=none
    else
        sudo bash /tmp/NVIDIA-installer.run --accept-license --no-questions --no-backup --ui=none
    fi
    mv /tmp/NVIDIA-installer.run .    # we need it later for the container
    echo -e "${GREEN}##########################################"
    echo "Finished nVidia driver installation "
    echo -e "##########################################${NC}"
    sleep 0.75
fi

# Install container manager and NVIDIA container toolkit
if [ -f /etc/redhat-release ]; then
    sudo yum install podman container-selinux -y
    CTRMGR="podman"
    echo -e "${GREEN}##########################################"
    echo "Installing nVidia container environment "
    echo -e "##########################################${NC}"
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
        && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
    sudo yum clean expire-cache
    sudo yum install -y nvidia-container-toolkit
    echo -e "${GREEN}##########################################"
    echo "Finished nVidia container environment "
    echo -e "##########################################${NC}"
    sleep 1
elif [ "$ID" == "ubuntu" ]; then
    CTRMGR="docker"
    if [ ! -f /usr/bin/docker ]; then
        curl --silent https://get.docker.com | sh  && sudo systemctl --now enable docker
    fi
    if ! dpkg -s nvidia-docker2 >/dev/null 2>&1; then
        echo -e "${GREEN}##########################################"
        echo "Installing nVidia container environment "
        echo -e "##########################################${NC}"
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
            && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
            && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt-get update
        sudo apt-get install -y nvidia-docker2
        sudo systemctl restart docker
        echo -e "${GREEN}##########################################"
        echo "Finished nVidia container environment "
        echo -e "##########################################${NC}"
        sleep 1
    fi
elif [ "$ID" == "amzn" ]; then
    CTRMGR="docker"
    if [ ! -f /usr/bin/docker ]; then
        if [ "$VERSION" == "2" ]; then
            sudo amazon-linux-extras install docker -y
            sudo systemctl enable docker
        else
            sudo yum install docker -y
        fi
        sudo service docker start
        sudo usermod -a -G docker ec2-user
    fi
else
    echo "OS not detected, not clear how to work with containers ..."
    exit 1
fi

# Build the container
echo -e "${GREEN}##########################################"
echo "NICE DCV Container Build starting ..."
echo -e "##########################################${NC}"
sleep 1

sudo $CTRMGR build -t "$target" .

echo -e "${GREEN}##########################################"
echo "NICE DCV Container Build finished." 
echo -e "##########################################${NC}"
sleep 2

# Run the container with port mapping and unique container name
container_name="dcv-${external_port}"

cmd="sudo $CTRMGR run -d --gpus all --privileged -p $external_port:$port --name $container_name $target"

eval $cmd

sleep 12

echo -e "${GREEN}##########################################"
echo "How to use the NICE DCV container"
echo -e "##########################################${NC}"
container_id=$(sudo $CTRMGR ps | grep "$container_name" | awk '{print $1}' | head -1)
if [ -z "$container_id" ]; then
    echo "It seems the container did not start properly ... please check the messages above."
    echo "Exiting ..."
    exit 1
fi
echo -e "The NICE DCV container id is \"$container_id\".\nHere is the output of the command \"sudo $CTRMGR ps\": ${GREEN} "
sudo $CTRMGR ps 
echo -e "${NC}"
echo "You can login to the container with the following command:"
echo -e "     ${GREEN}sudo $CTRMGR exec -ti $container_id /bin/bash${NC}"
echo 

# Configure dcv.conf inside the container
echo -e "${GREEN}##########################################"
echo "Configuring dcv.conf inside the container" 
echo -e "##########################################${NC}"

sudo $CTRMGR exec -ti $container_id bash -c "
set -e

echo 'Updating and upgrading packages...'
apt-get update && apt-get upgrade -y

echo 'Configuring dcv.conf...'
sed -i '/^\[session-management\]/,/^\[/s/^create-session = true/#create-session = true/' /etc/dcv/dcv.conf
sed -i '/^\[security\]/,/^\[/s/^#authentication=.*/authentication=\"none\"/' /etc/dcv/dcv.conf
sed -i '/^\[connectivity\]/,/^\[/s/^#web-port=.*/web-port=$port/' /etc/dcv/dcv.conf
sed -i '/^\[display\]/,/^\[/{/cuda-devices=\[/!{s/\(^\[display\]\)/\1\ncuda-devices=[\"0\"]/}}' /etc/dcv/dcv.conf
sed -i '/^\[display\]/,/^\[/{/web-client-max-head-resolution=/!{s/\(^\[display\]\)/\1\nweb-client-max-head-resolution=(4096, 2160)/}}' /etc/dcv/dcv.conf
sed -i '/^\[display\/linux\]/,/^\[/{/gl-displays=\[/!{s/\(^\[display\/linux\]\)/\1\ngl-displays=[\":0.0\"]/}}; \$a\[display/linux]\ngl-displays=[\":0.0\"]' /etc/dcv/dcv.conf

echo 'Restarting dcvserver...'
systemctl restart dcvserver

echo 'Creating and configuring init.sh...'
cd /var/lib/dcv
cat > init.sh <<EOF
#!/bin/bash
exec > >(tee -a /var/lib/dcv/init.log) 2>&1

echo 'Script started at $(date)'

# Set NVIDIA GPU as default
echo 'Setting NVIDIA GPU as default'
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export DISPLAY=:0  # Ensure we're using the main display

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

# Ensure necessary packages are installed
echo 'Checking and installing necessary packages'
apt-get update && apt-get install -y xorg openbox mesa-utils

# Check X server
echo 'Checking X server'
xdpyinfo || echo 'Failed to get display info'

# Start Openbox if not already running
if ! pgrep openbox > /dev/null; then
    echo 'Starting Openbox'
    openbox &
    sleep 2  # Give Openbox some time to start
else
    echo 'Openbox already running'
fi

echo 'Changing to Desktop directory' 
cd /var/lib/dcv/Desktop

echo 'Current directory: $(pwd)'
echo 'Checking GPU status'
glxinfo | grep "OpenGL renderer"
nvidia-smi

echo 'Launching game'

if [ ! -f "IntraverseClient.x86_64" ]; then
    echo 'Error: Game executable not found in $(pwd)'
    ls -l  # List directory contents for debugging
    exit 1
fi

# Use optirun or primusrun if available
if command -v optirun &> /dev/null; then
    LAUNCH_PREFIX="optirun"
elif command -v primusrun &> /dev/null; then
    LAUNCH_PREFIX="primusrun"
else
    LAUNCH_PREFIX=""
fi

# Launch the game with NVIDIA GPU and passed parameters
$LAUNCH_PREFIX ./IntraverseClient.x86_64 -authtoken eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2ZWVlOWUzOC1jZjQ4LTQ4MmMtOTg3NS0zY2ZhNWRiYjcyMzciLCJpYXQiOjE3MjUwNDc0OTksImV4cCI6MTcyNTA1ODI5OSwicm9sZXMiOlsic3VwZXJhZG1pbiJdLCJpc3MiOiJodHRwOi8vY29yZS1hcGktZGV2LmludHJhdmVyc2UuY29tIn0.Ut0JdN6iIeDKygPM1nFUz0wnvUnqIW2Dkmr0yUFgA6A \
-userid 6eee9e38-cf48-482c-9875-3cfa5dbb7237 \
-networkmode 5 \
-environmenttype development \
-api development \
-disablevoicechat true \
-restrictnetworktodevice false \
-userdevicetype desktop

echo 'Game launched'
echo 'Script completed at $(date)'
EOF

chmod +x /var/lib/dcv/init.sh
echo 'init.sh created and made executable in /var/lib/dcv'

echo 'Configuration completed successfully'
"

if [ $? -eq 0 ]; then
    echo "Container configuration completed successfully"
else
    echo "Error: Container configuration failed"
    exit 1
fi

# Stop the DCV container
echo "You can stop the container manually when done."