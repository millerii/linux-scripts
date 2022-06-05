#!/bin/bash

# Pop_OS #
##########

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


###-------------------------------------------------------------
# System settings

echo "Abiotic" > /etc/hostname

timedatectl set-timezone Europe/Helsinki
locale-gen en_US.UTF-8 fi_FI.UTF-8

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

###-------------------------------------------------------------

apt update
fwupdmgr get-devices
fwupdmgr get-updates
fwupdmgr update
apt full-upgrade -y
apt autoclean -y


###-------------------------------------------------------------
# System extension

apt install -y \
 ubuntu-restricted-extras \
 openssh-server \
 python3 python3-pip python-tk python2.7-minimal \
 build-essential \
 nautilus-admin \
 heif-gdk-pixbuf \
 curl \
 git \
 xclip \
 wget \
 gpg 

# Flatpak
apt install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
 
# SSTP protocol for VPN (for jamk)
add-apt-repository ppa:eivnaes/network-manager-sstp
apt install -y network-manager-sstp network-manager-sstp-gnome sstp-client

# Gnome Shell extensions
apt install -y gnome-shell-extensions bash curl dbus perl git less gir1.2-gmenu-3.0 gnome-menus
wget -O gnome-shell-extension-installer "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"
chmod +x gnome-shell-extension-installer
mv gnome-shell-extension-installer /usr/bin/


###-------------------------------------------------------------
# GUI programs

# Brave browser -source
apt install -y apt-transport-https curl
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
 | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

# VS-Codium -source
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
 | gpg --dearmor \
 | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
 | sudo tee /etc/apt/sources.list.d/vscodium.list
 
apt update
apt install -y \
 brave-browser \
 codium \
 guake \
 meld \
 tuxguitar tuxguitar-alsa tuxguitar-oss tuxguitar-jsa \
 gthumb


###-------------------------------------------------------------
# CLI programs

apt install -y \
 p7zip-full p7zip-rar \
 htop \
 traceroute \
 ipcalc \
 iperf 


###-------------------------------------------------------------
# deb-get

apt install -y curl
curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
deb-get update
deb-get install spotify-client 
deb-get install bitwarden 
deb-get install bat # A "cat" clone with wings.
deb-get install duf # Disk Usage/Free Utility - a better "df" alternative
deb-get install fd # A simple, fast and user-friendly alternative to "find"
deb-get install gh # GitHub-cli
deb-get install micro # cli text editor
deb-get install rpi-imager
deb-get install signal-desktop
deb-get install simplenote
deb-get install sublime-merge
deb-get install sublime-text
deb-get install teams
deb-get upgrade 


###-------------------------------------------------------------
# Flatpak

flatpak uninstall --delete-data com.spotify.Client

flatpak install -y flathub \
 com.github.maoschanz.drawing \
 com.usebottles.bottles '# windows app -run-manager'\
 com.github.PintaProject.Pinta \
 com.syntevo.SmartGit \
 org.telegram.desktop \
 com.github.tchx84.Flatseal '# flatpack permission manager' \
 de.haeckerfelix.Fragments '# torrent' \
 re.sonny.Tangram '# web-app-container' \
 fr.romainvigier.MetadataCleaner '# image-datacleaner' \
 com.github.liferooter.textpieces '# text-manipulator' \
 org.gnome.gitlab.YaLTeR.Identity '# image compare' \
 com.github.huluti.Curtail '# image compresser' \
 com.github.marktext.marktext '# markdown' \
 com.github.fabiocolacio.marker '# markdown' \
 com.leinardi.gwe '# sys info NVIDIA' \
 org.thonny.Thonny

flatpak update -y
flatpak uninstall --unused


###-------------------------------------------------------------
# End cleanup

apt autoremove -y
apt autoclean
