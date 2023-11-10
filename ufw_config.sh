#!/bin/bash

# Disable UFW to reset default rules
ufw disable

# Set default policies
ufw default deny incoming
ufw default deny outgoing

# Allow inbound SSH
ufw allow in ssh

# Allow outbound DNS for systemd-resolved
ufw allow out to 127.0.0.53 port 53

# Allow outbound HTTP, HTTPS and DNS
ufw allow out 80/tcp
ufw allow out 443/tcp
ufw allow out 53

# Enable UFW
echo 'y' | ufw enable
