#!/bin/bash

# check if there is an argument
if [ ! $# -eq 0 ]; then
  # if so, check the email address is valid
  if [[ $1 =~ [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]]; then
    echo "Valid email address: $email_address"
    $email_address = $1
  else
    echo "Email address $email_address is invalid - expect something like x@x.xx"
    exit 1
  fi
fi

function checkerror() {
  [[ $1 -ne 0 ]] && {
    echo "... operation failed, error code {$1}"
    exit 1
  }
}

function backupfile() {
  pathname=$1
  file=${pathname##*/}
  dt=$(date '+%Y%m%d-%H%M%S')
  echo "File $pathname already exists! backing up to $HOME/$file-$dt"
  cp -f -v $pathname $HOME/$file-$dt
  checkerror $?
}

if [[ $(id -u) -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# install automatic updates
echo "enable auto updates"
echo "... installing"
apt update
checkerror $?
apt install -y unattended-upgrades apt-transport-https ca-certificates apt-listchanges bsd-mailx
# need to run dpkg-reconfigure exim4-config to set as 'internet site'
# and if using healthchecks then also Unattended-Upgrade::Mail "your@email.com"; and Unattended-Upgrade::MailReport "always";
# in /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
echo ... creating schedule config file
configfile="/etc/apt/apt.conf.d/10periodic"
if [ -e $configfile ]; then
  backupfile $configfile
else
  cat >$configfile <<EOF
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

# if $email_address is not empty then set it
if [ -z "${email_address}" ]; then
  echo ... setting email address
  sed -i 's|^//[ \t]*Unattended-Upgrade::MailReport \"on-change\";|Unattended-Upgrade::MailReport \"always\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
  checkerror $?
  sed -i "s|^//[ \t]*Unattended-Upgrade::Mail \"\";|Unattended-Upgrade::Mail \"$email_address\";|g" /etc/apt/apt.conf.d/50unattended-upgrades
  checkerror $?
fi

echo ... enabling
configfile="/etc/apt/apt.conf.d/20auto-upgrades"
if [ -e $configfile ]; then
  backupfile $configfile
else
  cat >$configfile <<EOF
// from https://wiki.debian.org/UnattendedUpgrades
// most config in 10periodic
// Enable the update/upgrade script (0=disable)
APT::Periodic::Enable "1";
EOF
  checkerror $?
fi

# check if it's all ok
unattended-upgrade --verbose
checkerror $?

echo ... automatic upgrades configured
