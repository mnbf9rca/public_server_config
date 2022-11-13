#!/bin/bash

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install key packages, update system
echo "Updating catalogue..."
apt update
checkerror $?

echo "Removing snap"
apt purge -y snapd
checkerror $?

echo "updating the rest"
apt dist-upgrade --autoremove --no-install-recommends --assume-yes
checkerror $?

echo "checking no dangling versions left"
apt autoremove --assume-yes
checkerror $?

# install other useful apps
echo "installing other apps"
apt install -y nano curl
checkerror $?

# sudo no password
echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo "remember to set up UFW"
