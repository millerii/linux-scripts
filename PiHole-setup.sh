#!/bin/bash

# Headless PiHole setup script

YOURNAME=${SUDO_USER:-$USER}  # Get actual username who excecuted script, not the "sudo\root"
NEWUSERNAME="hole"

#######################
# Check that script is excecuted as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	exit
fi


if [ "$YOURNAME" == "pi" ]; then

	#######################
	# Set hostname
	echo "rpi-hole" > /etc/hostname


	#######################
	# Set NTP-server & timezone & locale configuration
	sed -i 's/#NTP=/NTP=fi.pool.ntp.org/g' /etc/systemd/timesyncd.conf
	sed -i -r 's/(^# ?)(en_US|fi_FI)(\.UTF-8 UTF-8)/\2\3/g' /etc/locale.gen
	locale-gen
	
	update-locale \
	 LANG="en_US.UTF-8" \
	 LANGUAGE="en" \
	 LC_NUMERIC="fi_FI.UTF-8" \
	 LC_TIME="fi_FI.UTF-8" \
	 LC_MONETARY="fi_FI.UTF-8" \
	 LC_PAPER="fi_FI.UTF-8" \
	 LC_IDENTIFICATION="fi_FI.UTF-8" \
	 LC_NAME="fi_FI.UTF-8" \
	 LC_ADDRESS="fi_FI.UTF-8" \
	 LC_TELEPHONE="fi_FI.UTF-8" \
	 LC_MEASUREMENT="fi_FI.UTF-8"

	timedatectl set-timezone Europe/Helsinki
	timedatectl set-ntp true
	systemctl enable systemd-time-wait-sync


	#######################
	# Rpi username change
	adduser --gecos "" $NEWUSERNAME
	if [ $? -eq 0 ]; then  # If user added successfull
		cp -v $0 /home/$NEWUSERNAME/  # Copy this script to new user
		chown -c $NEWUSERNAME:$NEWUSERNAME /home/$NEWUSERNAME/$0
		sed -i 's/:pi/:'$NEWUSERNAME'/g' /etc/group  # Replace 'pi' user rights to new username
		cp -rv /home/$YOURNAME/.ssh/ /home/$NEWUSERNAME/.ssh/  # Move ssh configs to new user
		chown -cR $NEWUSERNAME:$NEWUSERNAME /home/$NEWUSERNAME/.ssh/
		
		echo "*********************"
		echo "* User '$NEWUSERNAME' created."
		echo "* Next login as '$NEWUSERNAME' and run script again to finnish install."
		echo "*********************"
		read -p "Press [Enter] to logout"
		pkill -KILL -u pi
		exit 0
	else
		echo "Could not create new user"
		exit 1
	fi
fi


#######################
# Delete user 'pi'
if [ "$YOURNAME" == "$NEWUSERNAME" ] && (id -u "pi" &>/dev/nul); then
	killall -u pi
	deluser --remove-home pi
	if [ $? -ne 0 ]; then
		echo "User 'pi' could no be deleted"
		exit 1
	fi
else
	echo "Log in as user '$NEWUSERNAME' and run script"
	exit 1
fi


#######################
# raspi-config
echo -e "*************************
* In raspi-config:
* 1. Autologin on boot
* 3. Enable i2c, 1-wire
* 4. Change memory split
* 6. Expand filesystem
*************************"
read -p "Press [Enter] to open raspi-config"

raspi-config


#######################
# Full system update
apt update
apt full-upgrade -y
rpi-update

# Install nessessary "universal" packets etc.
apt install -y curl git wget python3 python3-pip i2c-tools screen


#######################
# micro -text editor [https://micro-editor.github.io]
apt install -y xclip
curl https://getmic.ro | bash
mv -v micro /usr/bin


#######################
# Pi-Hole
echo "**********************************************"
echo "* Next install Pi-Hole, default settings is OK"
echo "**********************************************"
read -p "Press [Enter] to continue install"
curl -sSL https://install.pi-hole.net | bash

# Change web-interface password
echo "************************************************"
echo "* Set new password for Web-Interface admin page:"
pihole -a -p

# Pihole Known whitelist [https://github.com/anudeepND/whitelist]
git clone https://github.com/anudeepND/whitelist.git
python3 whitelist/scripts/whitelist.py


#######################
# Unbound [https://docs.pi-hole.net/guides/dns/unbound/]
apt install -y unbound
wget -O root.hints https://www.internic.net/domain/named.root
mv -v root.hints /var/lib/unbound/
mv -v /home/$YOURNAME/unbound.conf /etc/unbound/unbound.conf.d/pi-hole.conf
service unbound start


#######################
# PiTFT
# [https://learn.adafruit.com/adafruit-pitft-28-inch-resistive-touchscreen-display-raspberry-pi/easy-install-2]
apt install -y git python3-pip
pip3 install --upgrade adafruit-python-shell click==7.0
git clone https://github.com/adafruit/Raspberry-Pi-Installer-Scripts.git
cd Raspberry-Pi-Installer-Scripts
# Auto configure PiTFT 2.4", 2.8", or 3.2" Resistive touchscreens
python3 adafruit-pitft.py --display=28r --rotation=90 --install-type=console --reboot=no -u /home/$YOURNAME
cd ..
rm -Rf Raspberry-Pi-Installer-Scripts/


#######################
# PADD
wget -N https://raw.githubusercontent.com/pi-hole/PADD/master/padd.sh

# Enable PADD run without password promt
echo "$YOURNAME ALL=(root) NOPASSWD: /home/$YOURNAME/padd.sh" > padd
chmod 0440 padd  # Change file permission to read only
chown root:root padd  # Change file owner to root
mv -v padd /etc/sudoers.d/padd
# Allow excecute padd.sh, but disable users write permission to prevent sudo-backdoor
chmod 0540 padd.sh


#######################
# Up-/downtime logger
bash < <(curl -Ls https://git.io/tuptime-install.sh)
# Filter events from the process CRON out of auth.log
sed -i -r 's+(^auth,authpriv\.\*)\t*(/var/log/auth\.log)+:programname, isequal, "CRON" ~\n&+g' /etc/rsyslog.conf


#######################
# End cleanup & Reboot
apt autoclean -y
# removes all stored archives in your cache for packages that can not be downloaded anymore (thus packages that are no longer in the repo or that have a newer version in the repo)
apt autoremove --purge

echo "************************************"
echo "* Reboot Raspberry to finalize setup"
read -p "Press [Enter] to reboot"

shutdown -r now
exit 0

