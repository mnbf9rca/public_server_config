#!/bin/bash

usage() { echo "Usage: $0 -u <username> -p <password>" 1>&2; exit 1; }

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

while getopts "u:p:" flag; do
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        *) usage ;;
    esac
done

if [ -z "${username}" ] || [ -z "${password}" ]; then
    usage
fi

hashed = mak

# create user
echo "Creating user $username"
adduser --gecos "" --disabled-password $username
checkerror $?

echo "setting password"
echo "$username":"$password" | chpasswd -e
checkerror $?

echo "Adding $username to sudo group"
usermod -aG sudo $username
checkerror $?

userhome = ~$username
echo "{$userhome}"
echo "Creating $userhome/.ssh"
mkdir $userhome/.ssh
checkerror $?

echo "downloading ssh keys"
wget -O~$username/.ssh/authorized_keys https://github.com/mnbf9rca.keys
checkerror $?

echo "... key saved"
echo "... chown"
chown -R $username:$username ~$username/.ssh
checkerror $?

echo "... chmod folder"
chmod 700 ~$username/.ssh
checkerror $?

echo "... chmod key"
chmod 600 ~$username/.ssh/authorized_keys
checkerror $?

echo "... key secured"
echo enabling cert auth
sed -i 's|[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

sed -i 's|[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
checkerror $?

systemctl reload sshd
checkerror $?






echo ... done
