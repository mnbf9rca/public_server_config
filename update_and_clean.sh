#!/bin/bash

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install key packages, update system
echo "Updating catalogue..."
apt update
checkerror $?

#echo "Removing snap"
#apt purge -y snapd
#checkerror $?

echo "updating the rest"
DEBIAN_FRONTEND=noninteractive apt dist-upgrade --autoremove --no-install-recommends --assume-yes
checkerror $?

echo "checking no dangling versions left"
DEBIAN_FRONTEND=noninteractive apt autoremove --assume-yes
checkerror $?

# install other useful apps
echo "installing other apps"
DEBIAN_FRONTEND=noninteractive apt install -y nano curl iputils-ping qemu-guest-agent
checkerror $?

# sudo no password
echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo "remember to set up UFW"
