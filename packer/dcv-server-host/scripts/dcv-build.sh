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
        echo -e "${GREEN}##########################################"
        echo -e "Disabling the nouveau driver"
        echo -e "##########################################${NC}"
        cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist nouveau
options nouveau modeset=0
EOF
        echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub > /dev/null
        sudo update-grub
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
    # install nVidia driver for "ubuntu"
    sudo apt-get update -y
    sudo apt-get install -y gcc make linux-headers-$(uname -r)
    sudo apt install -y awscli
    aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/latest/ .
    mv ./NVIDIA-Linux-x86_64*.run /tmp/NVIDIA-installer.run
    sudo bash /tmp/NVIDIA-installer.run --accept-license --no-questions --no-backup --ui=none
    mv /tmp/NVIDIA-installer.run .    # we need it later for the container
    echo -e "${GREEN}##########################################"
    echo "Finished nVidia driver installation "
    echo -e "##########################################${NC}"
    sleep 0.75
fi

# Install docker 
if [ "`which docker`" == "/usr/bin/docker" ] ; then
    :
else
    curl --silent https://get.docker.com | sh  && sudo systemctl --now enable docker
fi
if [ "`apt list  nvidia-docker2 2>&1 | grep installed`" == "" ] ; then
    echo -e "${GREEN}##########################################"
    echo "Installing nVidia container environment "
    echo -e "##########################################${NC}"
    distribution=$(. /etc/os-release;echo ubuntu$VERSION_ID) \
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

# Build the container
echo -e "${GREEN}##########################################"
echo "NICE DCV Container Build starting ..."
echo -e "##########################################${NC}"
sleep 1

sudo docker build -t "$target" .

echo -e "${GREEN}##########################################"
echo "NICE DCV Container Build finished." 
echo -e "##########################################${NC}"
sleep 2

# Run the container
cmd="sudo docker run  --gpus all --privileged --rm --network="host" $target &"

# Check for running container
check="`sudo docker ps | grep  $target`"
if [ "$check" != "" ] ; then
    id="`sudo docker ps | grep -v CONT | awk '{print $1}' | head -1`" 
    echo ""
    echo -e "${ORANGE}You have a container \"$target\" running already. You can stop it with \"sudo docker stop $id\".${NC}"
    echo -n "Do you want to create another DCV container anyway which might have some issues? (y/n) "
    read answer
    [ "$answer" != "y" ] && exit 
fi

eval $cmd

sleep 12

echo -e "${GREEN}##########################################"
echo "How to use the NICE DCV container"
echo -e "##########################################${NC}"
container_id=`sudo docker ps  | grep dcv | awk '{print $1}' | head -1`
if [ "$container_id" == "" ] ; then
    echo It seems the container did not start properly ... please check the messages above.
    echo Exiting ...
    exit
fi
echo -e "The NICE DCV container id is \"$container_id\".\nHere is the output of the command \"sudo docker ps\": ${GREEN} "
sudo docker ps 
echo -e "${NC}"
echo You can login to the container with the following command:
echo -e "     ${GREEN}sudo docker exec -ti $container_id /bin/bash${NC}"
echo 
