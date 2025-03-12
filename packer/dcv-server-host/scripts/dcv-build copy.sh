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
        exit
    fi
fi    

ip=`curl --silent http://169.254.169.254/latest/meta-data/local-ipv4 | grep \.`
if [ "$ip" == "" ] ; then
    onaws="0"
else
    onaws="1"
fi

# Install nVidia driver on host
smi_res=""
if [ -f /usr/bin/nvidia-smi ] ; then
    smi_res=`nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0 | sed -e 's/ /-/g' 2>&1`
fi

if [ "$smi_res" == "" -o "`echo $smi_res | grep 'NVIDIA-SMI has failed'`" != "" ] ; then
    echo -e "${GREEN}##########################################"
    echo -e "Starting nVidia driver installation "
    echo -e "##########################################${NC}"
    sleep 0.75
    if [ "`grep "blacklist nouveau" /etc/modprobe.d/blacklist.conf 2>&1 | grep -v 'No such' `" == "" ] ; then
        echo 
        echo -n "We will first disable the nouveau driver and reboot the server. Is this ok ? (y/n) "
        read answer
        if [ "$answer" == "y" -o "$answer" == "yes" ] ; then
            :
        else
            echo "Exiting ..."
            exit
        fi
        echo -e "${GREEN}##########################################"
        echo -e "Disabling the nouveau driver"
        echo -e "##########################################${NC}"
        cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist nouveau
options nouveau modeset=0
EOF
        echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub > /dev/null
        if [ "$ID" == "ubuntu" ] ; then
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
        sudo reboot # to remove nouveau driver in case
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
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    if [ "$ID" == "ubuntu" ] ; then
        # install nVidia driver for "ubuntu"
        sudo apt-get update -y
        sudo apt-get install -y gcc make linux-headers-$(uname -r)
        if [ "$onaws" == "0" ] ; then 
            wget -q http://us.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run -O /tmp/NVIDIA-installer.run
        else
            sudo apt install -y awscli
            aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/latest/ .
            mv ./NVIDIA-Linux-x86_64*.run /tmp/NVIDIA-installer.run
        fi
    else
        if [ "$ID" == "amzn" ] ; then
            sudo yum install -y gcc kernel-devel-$(uname -r) 
        else
            sudo yum -y install kernel-devel-`uname -r` kernel-headers-`uname -r`
            if [ "$distribution" == "centos7" ] ; then
                sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
            else
                sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
            fi
        fi
        sudo yum -y install dkms wget vim
        if [ "$onaws" == "0" ] ; then 
            wget -q http://us.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run -O /tmp/NVIDIA-installer.run
        else
            sudo yum install python3-pip -y
            pip3 install awscli --upgrade --user
            aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/latest/ .
            mv ./NVIDIA-Linux-x86_64*.run /tmp/NVIDIA-installer.run && chmod o+x /tmp/NVIDIA-installer.run
        fi
    fi
    if [ "$ID" == "amzn" -a "`uname -r | grep 5.10`" != "" ] ; then
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

# On Centos we use podman, on Ubuntu docker
if [ -f /etc/redhat-release ] ; then
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
elif [ "$ID" == "ubuntu" ] ; then
    CTRMGR="docker"
    if [ "`which docker`" == "/usr/bin/docker" ] ; then
        :
    else
        # Install docker 
        curl --silent https://get.docker.com | sh  && sudo systemctl --now enable docker
    fi
    if [ "`apt list  nvidia-docker2 2>&1 | grep installed`" == "" ] ; then
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
    echo
elif [ "$ID" == "amzn" ] ; then
    CTRMGR="docker"
    if [ "`which docker`" != "/usr/bin/docker" ] ; then
        if [ "$VERSION" == "2" ] ; then
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
    exit
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

# Run the container
if [ "$CTRMGR" == "docker" ] ; then
    if [ "$ID" == "amzn" ] ; then
        # cmd="sudo $CTRMGR run  --privileged --rm --network="host" $target &"
        cmd="$CTRMGR run  --privileged --rm --network="host" -v /tmp/.X11-unix:/tmp/.X11-unix -e DIPLAY=:1 -e XAUTHORITY=/run/user/1000/dcv/usersession.xauth $target &"
    else
        cmd="sudo $CTRMGR run  --gpus all --privileged --rm --network="host" $target &"
    fi
else
    cmd="sudo $CTRMGR run --security-opt=label=disable --hooks-dir=/usr/share/containers/oci/hooks.d/ --privileged --rm --network="host" $target &" 
fi

# Check for running container
check="`sudo $CTRMGR ps | grep  $target`"
if [ "$check" != "" ] ; then
    id="`sudo $CTRMGR ps | grep -v CONT | awk '{print $1}' | head -1`" 
    echo ""
    echo -e "${ORANGE}You have a container \"$target\" running already. You can stop it with \"sudo $CTRMGR stop $id\".${NC}"
    echo -n "Do you want to create another DCV container anyway which might have some issues? (y/n) "
    read answer
    [ "$answer" != "y" ] && exit 
fi

eval $cmd

sleep 12

echo -e "${GREEN}##########################################"
echo "How to use the NICE DCV container"
echo -e "##########################################${NC}"
container_id=`sudo $CTRMGR ps  | grep dcv | awk '{print $1}' | head -1`
if [ "$container_id" == "" ] ; then
    echo It seems the container did not start properly ... please check the messages above.
    echo Exiting ...
    exit
fi
echo -e "The NICE DCV container id is \"$container_id\".\nHere is the output of the command \"sudo $CTRMGR ps\": ${GREEN} "
sudo $CTRMGR ps 
echo -e "${NC}"
echo You can login to the container with the following command:
echo -e "     ${GREEN}sudo $CTRMGR exec -ti $container_id /bin/bash${NC}"
echo 

# Configure dcv.conf inside the container
echo -e "${GREEN}##########################################"
echo "Configuring dcv.conf inside the container" 
echo -e "##########################################${NC}"

sudo $CTRMGR exec -ti $container_id bash -c "
apt update -y
apt upgrade -y

sed -i '/^\\[session-management\\]/,/^\\[/{s/^create-session = true/#create-session = true/}' /etc/dcv/dcv.conf
sed -i '/^\\[display\\]/,/^\\[/{s/^#cuda-devices=.*/cuda-devices=[\"0\"]/}' /etc/dcv/dcv.conf
sed -i '/^\\[display\\]/,/^\\[/{s/^#web-client-max-head-resolution=.*/web-client-max-head-resolution=(4096, 2160)/}' /etc/dcv/dcv.conf
sed -i '/^\\[security\\]/,/^\\[/{s/^#authentication=.*/authentication=\"none\"/}' /etc/dcv/dcv.conf
sed -i '/^\\[display\\/linux\\]/,/^\\[/{s/^#gl-displays=.*/gl-displays=[\":0.0\"]/}' /etc/dcv/dcv.conf

systemctl restart dcvserver


# Create and configure init.sh
cd /var/lib/dcv
cat > init.sh <<'EOF'
#!/bin/bash
exec > >(tee -a /var/lib/dcv/init.log) 2>&1

echo "Script started at $(date)"

# Parse command-line arguments
userid="$1"
authtoken="$2"
api="$3"
disableVoiceChat="$4"
showdebugger="$5"
userdevicetype="$6"
avatarpreset="$7"
url="$8"

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
echo "Checking and installing necessary packages"
apt-get update && apt-get install -y xorg openbox mesa-utils

# Set up virtual framebuffer if needed
if [ -z "$DISPLAY" ]; then
    echo "Setting up Xvfb"
    Xvfb :99 -ac -screen 0 1920x1080x24 &
    export DISPLAY=:99
    sleep 2  # Give Xvfb some time to start
fi

echo "DISPLAY is set to: $DISPLAY"

# Check X server
echo "Checking X server"
xdpyinfo || echo "Failed to get display info"

# Start Openbox
echo "Starting Openbox"
openbox &
sleep 2  # Give Openbox some time to start

echo "Changing to Desktop directory"
cd /var/lib/dcv/Desktop

echo "Current directory: $(pwd)"
echo "Checking GPU status"
glxinfo | grep "OpenGL renderer"
nvidia-smi

echo "Launching game"

if [ ! -f "Development Client Build - Linux.x86_64" ]; then
    echo "Error: Game executable not found in $(pwd)"
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

echo "Game launched"
echo "Script completed at $(date)"
EOF

# Make the script executable
chmod +x /var/lib/dcv/init.sh

echo \"init.sh created and made executable in /var/lib/dcv\"
"

# Stop the DCV container
container_id=`sudo $CTRMGR ps  | grep dcv | awk '{print $1}' | head -1`
echo You can stop the container with the following command:
echo -