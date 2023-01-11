#!/bin/bash

usage() { echo "Usage: $0 -u <username> -k <github username>" 1>&2; exit 1; }

get_home() {
  local result; result="$(getent passwd "$1")" || return
  echo $result | cut -d : -f 6
}

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

while getopts "u:k:" flag; do
    case "${flag}" in
        u) username=${OPTARG};;
        k) githubuser=${OPTARG};;
        *) usage ;;
    esac
done

if [ -z "${githubuser}" ] || [ -z "${username}" ]; then
    usage
fi



echo "Testing keys for github user $githubuser"
echo "... getting temp file"
tmpfile=$(mktemp)
checkerror $?
echo "... downloading keys"
wget -O$tmpfile --no-cache https://github.com/${githubuser}.keys
checkerror $?
if [[ ! -s $tmpfile ]] 
then
    echo "... downloaded empty file for user - check https://github.com/${githubuser}.keys"
    rm $tmpfile
    exit 1
else
    rm $tmpfile
    checkerror $?
fi

# check that the user exists and has a home folder
echo "getting home dir for $username"
HOMEDIR="$(get_home $username)"
checkerror $?

# If folder $HOMEDIR/.ssh doesn't exist, create it
if [ ! -d "$HOMEDIR/.ssh" ]; then
    echo "creating .ssh folder"
    mkdir $HOMEDIR/.ssh
    checkerror $?
fi

cp ./ssh-key-sync.sh /opt/bin/ssh-key-sync.sh
checkerror $?
chmod +x /opt/bin/ssh-key-sync.sh
checkerror $?

# create /etc/systemd/system/ssh-key-sync.service with this content:
echo "creating /etc/systemd/system/ssh-key-sync.service"
cat > /etc/systemd/system/ssh-key-sync.service << EOF
[Unit]
Description=Synchronize ssh authorized keys with public keys from github.

[Service]
ExecStart=/opt/bin/ssh-key-sync.sh -u $username -k $githubuser
EOF
checkerror $?

# create /etc/systemd/system/ssh-key-sync.timer with this content:
echo "creating /etc/systemd/system/ssh-key-sync.timer"
cat > /etc/systemd/system/ssh-key-sync.timer << EOF
[Unit]
Description=Run ssk-key-sync every hour

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Unit=ssh-key-sync.service

[Install]
WantedBy=timers.target
EOF
checkerror $?

echo "enabling ssh-key-sync.timer"
systemctl enable ssh-key-sync.timer
checkerror $?
