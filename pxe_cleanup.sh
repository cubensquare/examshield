#!/bin/bash
# PXE Client Cleanup Script for Reducing ISO Size
# Usage: Run this script inside chroot to remove unnecessary files and shrink ISO size.

LOGFILE="/var/log/pxe_cleanup.log"
echo "[i] Starting PXE client cleanup..." | tee "$LOGFILE"

# === Remove unnecessary applications ===
echo "[i] Removing unused GUI applications, games, office tools..." | tee -a "$LOGFILE"
apt purge -y libreoffice* thunderbird* gnome-games*   hexchat* transmission* cheese* totem* rhythmbox*   simple-scan* shotwell* brasero* gimp* xterm*   gnome-mahjongg* gnome-mines* gnome-sudoku*   remmina* pidgin* xsane* > /dev/null 2>&1

# === Clean manual pages, locale, and doc files ===
echo "[i] Cleaning documentation, man pages, locales..." | tee -a "$LOGFILE"
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*
rm -rf /usr/share/info/*
rm -rf /usr/share/lintian/*
rm -rf /usr/share/locale/*

# Keep only English locale
mkdir -p /usr/share/locale/en
mv /usr/share/locale/en_US /usr/share/locale/
rm -rf /usr/share/locale/*_*

# === Remove GTK themes, icons, wallpapers ===
echo "[i] Removing unnecessary themes, wallpapers, and icons..." | tee -a "$LOGFILE"
rm -rf /usr/share/themes/*
rm -rf /usr/share/icons/*
rm -rf /usr/share/backgrounds/*

# === Clean apt cache ===
echo "[i] Cleaning apt cache..." | tee -a "$LOGFILE"
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/*
rm -rf /var/tmp/*

# === Remove unused libraries ===
echo "[i] Autoremoving orphaned libraries..." | tee -a "$LOGFILE"
apt autoremove -y

# === Remove logs and old configs ===
echo "[i] Removing logs and old configs..." | tee -a "$LOGFILE"
find /var/log -type f -exec truncate -s 0 {} \;
rm -rf /root/.cache/*
rm -rf /home/*/.cache/*
rm -rf /home/*/.local/share/recently-used.xbel

echo "[✓] Cleanup completed. System is now lighter." | tee -a "$LOGFILE"
