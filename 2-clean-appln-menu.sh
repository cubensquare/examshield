#!/bin/bash
# Run this script inside chroot

# Ensure required packages are still present
REQUIRED=("firefox-esr" "thunar")  # Thunar is XFCE's File Manager

# Remove unwanted XFCE desktop entries (menu items)
echo "[i] Removing unnecessary XFCE menu entries..."

# Create folder to override menu
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

# Remove unwanted applications
echo "[i] Removing unwanted packages..."
apt purge -y libreoffice* thunderbird* mousepad xfce4-terminal xfce4-settings xfce4-about* \
  xscreensaver* abiword* gnumeric* gedit* atril* hexchat* parole* pidgin* orage* \
  ristretto* xfce4-appfinder xfce4-screenshooter xfce4-taskmanager gnome-software \
  synaptic

# Autoremove dependencies and clean
apt autoremove -y
apt clean

echo "[✓] XFCE menu cleaned. Only Firefox and File Manager retained."
