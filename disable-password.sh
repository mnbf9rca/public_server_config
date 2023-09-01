#!/bin/bash

# Function to handle errors
function checkerror() {
  [[ $1 -ne 0 ]] && {
    echo "... operation failed, error code {$1}"
    exit 1
  }
}

# Check if the script is run as root
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# Backup the SSH configuration file
backup_path="/etc/ssh/sshd_config.backup.$(date +%Y%m%d%H%M%S)"
echo "Backing up current SSH configuration to $backup_path"
cp /etc/ssh/sshd_config "$backup_path"
checkerror $?

# Disable password authentication
echo "Disabling password authentication..."
sed -i 's|^[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

# Disable challenge response authentication
echo "Disabling challenge response authentication..."
sed -i 's|^[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
checkerror $?

# Enable public key authentication
echo "Enabling public key authentication..."
sed -i 's|^[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
checkerror $?

# Disable root login
echo "Disabling root login..."
sed -i 's|^[#]*PermitRootLogin yes|PermitRootLogin no|g' /etc/ssh/sshd_config
checkerror $?

# Reload SSHD to apply changes
echo "Reloading SSHD to apply changes..."
systemctl reload sshd
checkerror $?

echo "... SSH configuration updated successfully"
