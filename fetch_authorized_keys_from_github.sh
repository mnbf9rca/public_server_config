#!/bin/bash

usage() {
  echo "Usage: $0 <github username>"
  echo "Example: $0 githubuser"
  exit 1
}

function checkerror() {
  [[ $1 -ne 0 ]] && {
    echo "... operation failed, error code {$1}"
    exit 1
  }
}

if [[ $(id -u) -eq 0 ]]; then
  echo "Please run as normal user, not as root"
  exit 1
fi

githubuser=$1

# Validate input
if [ -z "${githubuser}" ]; then
  usage
fi

echo "Testing keys for GitHub user $githubuser"
echo "... getting temp file"
tmpfile=$(mktemp)
checkerror $?
echo "... downloading keys"
wget --https-only -O$tmpfile --no-cache https://github.com/${githubuser}.keys
checkerror $?
if [[ ! -s $tmpfile ]]; then
  echo "... downloaded empty file for user - check https://github.com/${githubuser}.keys"
  rm $tmpfile
  exit 1
else
  rm $tmpfile
  checkerror $?
fi

echo "Getting home dir for current user"
HOMEDIR="$(eval echo ~$USER)"
checkerror $?

echo "Home in ${HOMEDIR}"
echo "Creating $HOMEDIR/.ssh"
mkdir -p "$HOMEDIR/.ssh"
checkerror $?


echo "Downloading SSH keys"
# Download to temp file first
tmpkeys=$(mktemp)
wget --https-only -O"$tmpkeys" --no-cache "https://github.com/${githubuser}.keys"
checkerror $?

# Create authorized_keys if it doesn't exist
touch "$HOMEDIR/.ssh/authorized_keys"

# Process each key
while IFS= read -r newkey; do
    if [[ "$newkey" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)[[:space:]] ]]; then
        if ! grep -qF "$newkey" "$HOMEDIR/.ssh/authorized_keys"; then
            echo "$newkey" >>"$HOMEDIR/.ssh/authorized_keys"
        fi
    else
        echo "Warning: Invalid key format detected, skipping"
    fi
done <"$tmpkeys"

# Cleanup
rm "$tmpkeys"
checkerror $?

echo "... key saved"
echo "... chown"
chown -R "$USER:$USER" "$HOMEDIR/.ssh"
checkerror $?

echo "... chmod folder"
chmod 700 "$HOMEDIR/.ssh"
checkerror $?

echo "... chmod key"
chmod 600 "$HOMEDIR/.ssh/authorized_keys"
checkerror $?

echo "... key secured"

echo "Enabling cert auth"
# Create backup with timestamp
timestamp=$(date '+%Y%m%d_%H%M%S')
sudo cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.backup_${timestamp}"
sudo chmod 600 "/etc/ssh/sshd_config.backup_${timestamp}"
checkerror $?

sudo sed -i 's|[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

sudo sed -i 's|[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
checkerror $?

# echo "Disabling password auth"
# sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
# checkerror $?

echo "Reloading sshd"
if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl not found. Using service command..."
  sudo service sshd reload
else
  sudo systemctl reload sshd
fi
checkerror $?

echo "... done"
