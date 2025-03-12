#!/bin/bash

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

export -f log

echo "$(date '+%Y-%m-%d %H:%M:%S') - Including common functions." | sudo tee -a /var/log/userdata.log