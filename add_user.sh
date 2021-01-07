#!/bin/bash


if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

while getopts u:a:f: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
    esac
done
if [ -z "$var" ];
then
    echo "set -u flag"
    exit 1
else
    echo "Username: $username";
fi

# create user
echo "Creating user $username"
adduser $username
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
