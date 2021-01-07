#!/bin/bash

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install key packages, update system
echo "Updating catalogue..."
apt update
retVal=$?
checkerror $?

echo "Removing snap"
apt purge -y snapd
retVal=$?
checkerror $?

echo "updating the rest"
apt dist-upgrade --autoremove --no-install-recommends --assume-yes
retVal=$?
checkerror $?

# install other useful apps
echo "installing other apps"
apt install -y nano curl
retVal=$?
checkerror $?
