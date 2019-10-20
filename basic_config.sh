#!/bin/bash


if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
# install authorized_keys
#
# FIRST, DOWNLOAD AUTHORIZED_KEYS
wget -Oauthorized_keys https://raw.githubusercontent.com/mnbf9rca/public_server_config/master/authorized_keys

#

echo Installing keys
cd ~
mkdir ~/.ssh
cp  ~/authorized_keys ~/.ssh/authorized_keys
echo ... key saved
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
echo ... key secured

# ensure cart auth is allowed authentication
echo enabling cert auth
sed -i 's|[#]*ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|g' /etc/ssh/sshd_config
sed -i 's|[#]*PubkeyAuthentication no|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
echo ... reloading sshd
systemctl reload sshd

# install key packages, update system
apt-get update
apt-get dist-upgrade --autoremove --no-install-recommends --assume-yes
# install other useful apps
echo installing other apps
apt-get install -y nano open-vm-tools

# install automatic updates
echo enable auto updates
echo ... installing
wget -O10periodic https://raw.githubusercontent.com/mnbf9rca/public_server_config/master/10periodic

apt-get install -y unattended-upgrades apt-transport-https ca-certificates
echo ... setting timing
sed -i 's|^//[ \t]\"\${distro_id}:\${distro_codename}-updates\"|"\${distro_id}:\${distro_codename}-updates\"|g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|^//[ \t]*Unattended-Upgrade::Automatic-Reboot \"false\";|Unattended-Upgrade::Automatic-Reboot \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|^//[ \t]*Unattended-Upgrade::Remove-Unused-Dependencies \"false\";|Unattended-Upgrade::Remove-Unused-Dependencies   \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|^//[ \t]*Unattended-Upgrade::AutoFixInterruptedDpkg \"false\";|Unattended-Upgrade::AutoFixInterruptedDpkg \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
cp 10periodic /etc/apt/apt.conf.d/10periodic
echo ... automatic upgrades configured

echo ... done
