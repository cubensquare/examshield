#!/bin/bash
# Purpose: Remove unnecessary GUI applications and XFCE menu clutter inside PXE client chroot
# Run this script INSIDE chroot after all other configuration

echo "[i] Ensuring Firefox and Thunar remain installed..."
REQUIRED=("firefox-esr" "thunar")
apt install -y "${REQUIRED[@]}"

echo "[i] Removing unnecessary XFCE menu entries..."
mkdir -p /etc/xdg/menus
cat <<EOF > /etc/xdg/menus/xfce-applications.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
 "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
    <Name>Applications</Name>
    <DefaultAppDirs/>
    <DefaultDirectoryDirs/>
    <Include>
        <Category>Network</Category>
        <Category>Utility</Category>
    </Include>
    <Exclude>
        <Filename>exo-mail-reader.desktop</Filename>
        <Filename>exo-terminal-emulator.desktop</Filename>
        <Filename>xfce4-about.desktop</Filename>
        <Filename>xfce4-session-logout.desktop</Filename>
        <Filename>xfce4-settings-manager.desktop</Filename>
    </Exclude>
</Menu>
EOF

echo "[i] Removing Office, Graphics, Multimedia, Accessories, and unused apps..."
apt purge -y \
  libreoffice* thunderbird* abiword* gnumeric* gedit* atril* hexchat* pidgin* orage* \
  ristretto xsane* gimp* shotwell eog \
  exfalso parole pavucontrol quodlibet xfburn vlc* sound-juicer \
  catfish xfce4-appfinder thunar* xarchiver mousepad xfce4-screenshooter \
  xfce4-taskmanager xfce4-clipman galculator xfce4-sensors-plugin xfce4-terminal \
  debian-reference* xfce4-dict gnome-disk-utility xfce4-notes-plugin bulk-rename \
  gnome-software synaptic xfce4-about* xscreensaver*

echo "[i] Autoremoving dependencies and cleaning apt cache..."
apt autoremove -y
apt clean

echo "[i] Cleaning temp, cache and unused data to reduce ISO size..."
rm -rf /tmp/* /var/tmp/* /var/cache/* /var/lib/apt/lists/* /root/.cache/*

echo "[✓] Unwanted applications and menu items removed. Minimal ISO with Firefox ready."
