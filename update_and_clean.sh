#!/bin/bash


if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install key packages, update system
echo "Updating catalogue..."
apt update
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo "Removing snap"
apt purge -y snapd
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo "updating the rest"
apt dist-upgrade --autoremove --no-install-recommends --assume-yes
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
# install other useful apps
echo "installing other apps"
apt install -y nano curl
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
