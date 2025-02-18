#!/bin/bash

# Function to validate email address
function validate_email() {
  if [[ ! "$1" =~ [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]]; then
    echo "Email address $1 is invalid - expect something like x@x.xx"
    exit 1
  fi
}

# Error handling function
function checkerror() {
  [[ $1 -ne 0 ]] && {
    echo "... operation failed, error code {$1}"
    exit 1
  }
}

# Backup file function
function backupfile() {
  pathname="$1"
  file=${pathname##*/}
  dt=$(date '+%Y%m%d-%H%M%S')
  echo "File $pathname already exists! Backing up to $HOME/$file-$dt"
  cp -f -v "$pathname" "$HOME/$file-$dt"
  checkerror $?
}

# Check if script is run as root
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# Check if email address is provided and validate it
if [ ! -z "$1" ]; then
  validate_email "$1"
  EMAIL_ADDRESS="$1"
fi

# Install automatic updates
echo "Enabling automatic updates..."
DEBIAN_FRONTEND=noninteractive apt update
checkerror $?
DEBIAN_FRONTEND=noninteractive apt install -y unattended-upgrades apt-transport-https ca-certificates apt-listchanges bsd-mailx
checkerror $?

# Configuration file updates
# need to run dpkg-reconfigure exim4-config to set as 'internet site'
# Force clear old Exim configuration settings
echo "... resetting Exim configuration"
echo "PURGE" | debconf-communicate exim4-config
checkerror $?

# Pre-seed Exim configuration
echo "... configuring exim4"
sed -i 's/^dc_eximconfig_configtype=.*/dc_eximconfig_configtype="internet"/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_local_interfaces=.*/dc_local_interfaces="127.0.0.1 ; ::1"/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_other_hostnames=.*/dc_other_hostnames="'$HOSTNAME'"/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_readhost=.*/dc_readhost=""/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_relay_domains=.*/dc_relay_domains=""/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_relay_nets=.*/dc_relay_nets=""/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_smarthost=.*/dc_smarthost=""/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_mailname=.*/dc_mailname="'$HOSTNAME'"/' /etc/exim4/update-exim4.conf.conf
sed -i 's/^dc_use_split_config=.*/dc_use_split_config="false"/' /etc/exim4/update-exim4.conf.conf


# Update Exim configuration
update-exim4.conf
checkerror $?
systemctl restart exim4
checkerror $?



# and if using healthchecks then also Unattended-Upgrade::Mail "your@email.com"; and Unattended-Upgrade::MailReport "always";
# in /etc/apt/apt.conf.d/50unattended-upgrades
# checkerror $?
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

echo ... adding debian updates to sources
sed -i 's|^[\/]\{0,2\}[ \t]*\"origin=Debian,codename=\${distro_codename}-updates\";|\"origin=Debian,codename=\${distro_codename}-updates\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
sed -i 's|^[\/]\{0,2\}[ \t]*\"\${distro_id}:\${distro_codename}-updates\";|\"\${distro_id}:\${distro_codename}-updates\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?

# check if /etc/apt/apt.conf.d/50unattended-upgrades contains "Unattended-Upgrade::Origins-Pattern" anywhere
# if not, add it
if grep -q -E -E "^Unattended-Upgrade::Origins-Pattern {" /etc/apt/apt.conf.d/50unattended-upgrades; then
  echo ... Unattended-Upgrade::Origins-Pattern exists and is not disabled
elif grep -q -E "^[\/]{2}[ \t]*Unattended-Upgrade::Origins-Pattern {" /etc/apt/apt.conf.d/50unattended-upgrades; then
  echo ... Unattended-Upgrade::Origins-Pattern exists but is disabled
  echo ... can\'t automatically enable it
  echo ... please enable it manually
  exit 1
elif grep -q "Unattended-Upgrade::Allowed-Origins" /etc/apt/apt.conf.d/50unattended-upgrades; then
  echo ... Unattended-Upgrade::Origins-Pattern does not exist
  echo ... Unattended-Upgrade::Allowed-Origins does exist
  echo ... adding Unattended-Upgrade::Origins-Pattern just above Unattended-Upgrade::Allowed-Origins
  sed -i 's|^Unattended-Upgrade::Allowed-Origins {|Unattended-Upgrade::Origins-Pattern {\n}\nUnattended-Upgrade::Allowed-Origins {|g' /etc/apt/apt.conf.d/50unattended-upgrades
  checkerror $?
else
  echo ... Unable to find Unattended-Upgrade::Origins-Pattern or Unattended-Upgrade::Allowed-Origins
  echo ... ending
  exit 1
fi

# check for multiline regex "^Unattended-Upgrade::Origins-Pattern {[.\n]*\"origin=\*\"[.\n]*}" in /etc/apt/apt.conf.d/50unattended-upgrades
# if not, add it
if grep -Pzoq "Unattended-Upgrade::Origins-Pattern {[.\n]*\"origin=\*\"[.\n]*}" /etc/apt/apt.conf.d/50unattended-upgrades; then
  echo ... \"origin=*\" already in sources
  echo ... checking it\'s not disabled
  if grep -Pzoq "Unattended-Upgrade::Origins-Pattern {[.\n]*[\/]{2}[ \t]*\"origin=\*\"[.\n]*}" /etc/apt/apt.conf.d/50unattended-upgrades; then
    echo ... \"origin=*\" is disabled
    echo ... enabling it
    perl -pi -e '/Unattended-Upgrade::Origins-Pattern {/../}/ and s/[\/]{2}[ \t]*\"origin=\*\"/\"origin=\*\"/g' /etc/apt/apt.conf.d/50unattended-upgrades
    checkerror $?
  else
    echo ... \"origin=*\" is enabled
  fi
else
  echo ... adding \"origin=*\" to sources
  sed -i 's|^Unattended-Upgrade::Origins-Pattern {|Unattended-Upgrade::Origins-Pattern {\n"origin=*";|g' /etc/apt/apt.conf.d/50unattended-upgrades
  checkerror $?
fi

echo ... setting automatic reboot
sed -i 's|^[\/]\{0,2\}[ \t]*Unattended-Upgrade::Automatic-Reboot \"*.\";|Unattended-Upgrade::Automatic-Reboot \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
echo ... setting remove Dependencies
sed -i 's|^[\/]\{0,2\}[ \t]*Unattended-Upgrade::Remove-Unused-Dependencies \"*.\";|Unattended-Upgrade::Remove-Unused-Dependencies \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?
echo ... setting automatic fix interrupted packages
sed -i 's|^[\/]\{0,2\}[ \t]*Unattended-Upgrade::AutoFixInterruptedDpkg \"*.\";|Unattended-Upgrade::AutoFixInterruptedDpkg \"true\";|g' /etc/apt/apt.conf.d/50unattended-upgrades
checkerror $?

# If email address is provided, set it
if [ ! -z "${EMAIL_ADDRESS}" ]; then
  echo "... setting email notification to always"
  # sed command to match [\/]{0,2}[ \t]*Unattended-Upgrade::MailReport \".*\";\n and replace it with Unattended-Upgrade::MailReport "always"\n
  sed -i 's|^[\/]\{0,2\}[ \t]*Unattended-Upgrade::MailReport \".*\";|Unattended-Upgrade::MailReport "always";|g' /etc/apt/apt.conf.d/50unattended-upgrades
  checkerror $?
  echo ... setting email address
  sed -i "s|^[\/]\{0,2\}[ \t]*Unattended-Upgrade::Mail \"\";|Unattended-Upgrade::Mail \"$EMAIL_ADDRESS\";|g" /etc/apt/apt.conf.d/50unattended-upgrades
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

# Check if all configurations are OK
unattended-upgrade --verbose
checkerror $?

echo "... automatic upgrades configured"
