#!/bin/bash
# disable-desktop-icons.sh
# Purpose: Hide all desktop icons and disable right-click menu in XFCE

PXE_USER=$(logname)

echo "[i] Disabling desktop icons and right-click for user: $PXE_USER"

sudo -u "$PXE_USER" xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -n -t bool -s false
sudo -u "$PXE_USER" xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -n -t bool -s false
sudo -u "$PXE_USER" xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -n -t bool -s false
sudo -u "$PXE_USER" xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -n -t bool -s false
sudo -u "$PXE_USER" xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s false

# Disable right-click menu on desktop
sudo -u "$PXE_USER" xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 0

echo "[✓] Desktop cleanup and right-click disabled."
