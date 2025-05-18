#!/bin/bash
# Purpose: Remove unnecessary GUI applications to reduce ISO size and declutter menu

echo "[i] Removing Graphics applications..."
apt purge -y \
  ristretto \
  xsane* \
  gimp* \
  shotwell \
  eog

echo "[i] Removing Multimedia applications..."
apt purge -y \
  exfalso \
  parole \
  pavucontrol \
  quodlibet \
  xfburn \
  vlc* \
  sound-juicer

echo "[i] Removing Accessories..."
apt purge -y \
  catfish \
  xfce4-appfinder \
  thunar* \
  xarchiver \
  mousepad \
  xfce4-screenshooter \
  xfce4-taskmanager \
  xfce4-clipman \
  galculator \
  xfce4-sensors-plugin \
  xfce4-terminal \
  debian-reference* \
  xfce4-dict \
  gnome-disk-utility \
  gedit \
  xfce4-notes-plugin \
  bulk-rename

echo "[i] Cleaning up..."
apt autoremove -y
apt clean

echo "[i] Cleaning temporary files..."
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/*
rm -rf /var/lib/apt/lists/*
rm -rf /root/.cache/*

echo "[✓] Unwanted applications and menu items removed successfully."
