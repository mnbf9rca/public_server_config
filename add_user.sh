#!/bin/bash

usage() { echo "Usage: $0 -u <username> -p <password>" 1>&2; exit 1; }

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

get_home() {
  local result; result="$(getent passwd "$1")" || return
  echo $result | cut -d : -f 6
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

echo enabling cert auth
sed -i 's|[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

sed -i 's|[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
checkerror $?

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

echo "getting home dir for $username"
HOMEDIR="$(get_home $username)"
checkerror $?

echo "home in {$HOMEDIR}"
echo "Creating $HOMEDIR/.ssh"
mkdir $HOMEDIR/.ssh
checkerror $?

echo "downloading ssh keys"
wget -O$HOMEDIR/.ssh/authorized_keys https://github.com/mnbf9rca.keys
checkerror $?

echo "... key saved"
echo "... chown"
chown -R $username:$username $HOMEDIR/.ssh
checkerror $?

echo "... chmod folder"
chmod 700 $HOMEDIR/.ssh
checkerror $?

echo "... chmod key"
chmod 600 $HOMEDIR/.ssh/authorized_keys
checkerror $?

echo "... key secured"

systemctl reload sshd
checkerror $?

echo ... done
