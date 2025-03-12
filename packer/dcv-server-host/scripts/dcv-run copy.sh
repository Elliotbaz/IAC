#!/bin/bash

function tailDcvLog {
    echo "Waiting for X and DCV Server to initialize ... "
    echo
    while [[ ! -f /var/log/dcv/server.log ]]; do
        # echo -n '.'
        sleep 3
    done
    # echo -n '.'
    sleep 3
    # echo " OK"
    # uncomment the following line in case you want to see the DCV server log
    # tail -f -n500 /var/log/dcv/server.log
}

# Disable nouveau
# if [ -f /usr/bin/nvidia-smi -a ! -f /etc/modprobe.d/blacklist.conf ]; then
#     cat >> /etc/modprobe.d/blacklist.conf <<EOF
# blacklist nouveau
# options nouveau modeset=0
# EOF
# fi

# Configure the NICE DCV License
ip=$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4 | grep \.)
if [ "$ip" == "" ]; then
    # We are not on AWS and need a DCV trial license
    cp /etc/dcv/dcv.conf /etc/dcv/dcv.conf.org
    cat /etc/dcv/dcv.conf.org | awk '/#license-file/ {print "license-file = \"/etc/dcv/license.lic\""}; {print}' > /etc/dcv/dcv.conf
    pubip="Public_IP_or_Server_Name"
else
    # on AWS NICE DCV please enable license access to the S3 bucket
    pubip=$(curl --silent http://169.254.169.254/latest/meta-data/public-ipv4 | grep \.)
fi

# Enable the DCV service 
# res1=$(systemctl enable dcvserver 2>&1)

RED='\033[0;31m'; GREEN='\033[0;32m'; GREY='\033[0;37m'; BLUE='\034[0;37m'; NC='\033[0m'
ORANGE='\033[0;33m'; BLUE='\033[0;34m';
echo
echo -e "${GREEN}##########################################"
echo "NICE DCV Container starting up ... "
echo -e "##########################################${NC}"
echo

# Show DCV Server log in case 
tailDcvLog &

# Setup user and DCV session
(
    sleep 5; /usr/local/bin/dcv-start.sh;

    RED='\033[0;31m'; GREEN='\033[0;32m'; GREY='\033[0;37m'; BLUE='\034[0;37m'; NC='\033[0m'
    ORANGE='\033[0;33m'; BLUE='\033[0;34m';
    echo
    echo -e "${GREEN}###############################################"
    echo "Your NICE DCV Session is ready to login to ... "
    echo -e "###############################################${NC}"
    echo
    echo "The default user name is “user” and the password “dcv” (can be adapted in “startup_script.sh”)."
    echo
    echo "To connect to DCV you have 2 options: "
    echo
    # echo -e '\e]8;;http://example.com\aThis is a link\e]8;;\a'
    echo -e "Web browser: ${GREEN}\e]8;;https://${pubip}:8443\ahttps://${pubip}:8443\e]8;;\a${NC} (you can accept the security exception as there is no SSL certificate installed) – or –"
    echo
    echo -e "DCV native client for best performance: Enter “${GREEN}${pubip}${NC}” in the connection field (the portable DCV client can be downloaded here: https://download.nice-dcv.com/)"
    echo
) &

# echo ">> Exec /usr/sbin/init"
exec /usr/sbin/init
