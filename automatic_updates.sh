#!/bin/bash

function checkerror() {
   
   [[ $1 -ne 0 ]] && { echo "... operation failed, error code {$1}"; exit 1 ; } 
}

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install automatic updates
echo "enable auto updates"
echo "... installing"
apt update
checkerror $?
apt install -y unattended-upgrades apt-transport-https ca-certificates apt-listchanges bsd-mailx
checkerror $?
echo ... creating config file
configfile="/etc/apt/apt.conf.d/10periodic"
if [ -e $configfile ]; then
  echo "File $configfile already exists! backing up"
  cp -f -v $configfile $configfile.bak
else
  cat > $configfile <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
checkerror $?
fi

echo ... setting timing
sed -i 's|^//[ \t]\"\${distro_id}:\${distro_codename}-updates\"|"\${distro_id}:\${distro_codename}-updates\"|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
sed -i 's|^//[ \t]*Unattended-Upgrade::Automatic-Reboot \"false\";|Unattended-Upgrade::Automatic-Reboot \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
sed -i 's|^//[ \t]*Unattended-Upgrade::Remove-Unused-Dependencies \"false\";|Unattended-Upgrade::Remove-Unused-Dependencies   \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
sed -i 's|^//[ \t]*Unattended-Upgrade::AutoFixInterruptedDpkg \"false\";|Unattended-Upgrade::AutoFixInterruptedDpkg \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?

echo ... automatic upgrades configured
