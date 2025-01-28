#!/bin/bash

# Disable UFW to reset default rules
echo 'y' | ufw reset

# Allow inbound SSH
ufw allow in ssh

# Set default policies
ufw default deny incoming
ufw default deny outgoing

# Allow outbound DNS for systemd-resolved
ufw allow out to 127.0.0.53 port 53

# Allow outbound HTTP, HTTPS, NTP, DNS
ufw allow out http
ufw allow out https
ufw allow out dns
ufw allow out ntp

# block loopback
ufw allow in on lo
ufw allow out on lo
ufw deny in from 127.0.0.0/8
ufw deny in from ::1

# Enable UFW
echo 'y' | ufw enable
