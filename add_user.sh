#!/bin/bash

usage() { echo "Usage: $0 -u <username> -p <password>" 1>&2; exit 1; }

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

while getopts u:p: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        \?) usage
    esac
done
if [ -z "$username" ]; then usage fi
if [ -z "$password" ]; then usage fi


# create user
echo "Creating user $username"
useradd --create-home --password $password $username
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo "Adding $username to sudo group"
usermod -aG sudo $username
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}


# install authorized_keys
#
echo "Creating $username/.ssh"
mkdir $username/.ssh
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo "downloading ssh keys"
wget -O$username/.ssh/authorized_keys https://github.com/mnbf9rca.keys
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo "... key saved"
echo "... chown"
chown -R $username:$username $username/.ssh
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
echo "... chmod folder"
chmod 700 $username/.ssh
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
echo "... chmod key"
chmod 600 $username/.ssh/authorized_keys
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
echo ... key secured

echo "installing openssh"

# ensure cart auth is allowed authentication
echo enabling cert auth
sed -i 's|[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
sed -i 's|[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}
echo ... reloading sshd
systemctl reload sshd
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}


echo ... done
