#!/bin/bash

usage() { 
  echo "Usage: $0 -u <username> -p <password> -k <github username>"
  echo "Example: $0 -u newuser -p secret -k githubuser"
  exit 1
}

function checkerror() {
  [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; }
}

get_home() {
  local result; result="$(getent passwd "$1")" || { echo "Cannot find home directory for $1"; exit 1; }
  echo $result | cut -d : -f 6
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

while getopts "u:p:k:" flag; do
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        k) githubuser=${OPTARG};;
        *) usage ;;
    esac
done

# Validate input
if [[ ! "$username" =~ ^[a-zA-Z0-9_]+$ ]] || [ -z "${githubuser}" ] || [ -z "${password}" ]; then
    usage
fi

# Check if user already exists
if id "$username" &>/dev/null; then
  echo "User $username already exists!"
  exit 1
fi

echo "Testing keys for GitHub user $githubuser"
echo "... getting temp file"
tmpfile=$(mktemp)
checkerror $?
echo "... downloading keys"
wget -O$tmpfile --no-cache https://github.com/${githubuser}.keys
checkerror $?
if [[ ! -s $tmpfile ]]; then
    echo "... downloaded empty file for user - check https://github.com/${githubuser}.keys"
    rm $tmpfile
    exit 1
else
    rm $tmpfile
    checkerror $?
fi

# create user
echo "Creating user $username"
adduser --gecos "" --disabled-password $username
checkerror $?

echo "Setting password"
echo "$username":"$password" | chpasswd 
checkerror $?

echo "Adding $username to sudo group"
usermod -aG sudo $username
checkerror $?

echo "Getting home dir for $username"
HOMEDIR="$(get_home $username)"
checkerror $?

echo "Home in {$HOMEDIR}"
echo "Creating $HOMEDIR/.ssh"
mkdir $HOMEDIR/.ssh
checkerror $?

echo "Downloading SSH keys"
wget -O$HOMEDIR/.ssh/authorized_keys --no-cache https://github.com/${githubuser}.keys
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

echo "Enabling cert auth"
sed -i 's|[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

sed -i 's|[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
checkerror $?

echo "Disabling password auth"
sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

echo "Reloading sshd"
systemctl reload sshd
checkerror $?

echo "... done"
