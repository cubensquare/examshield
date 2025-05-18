#!/bin/bash
# Script: remove-office.sh
# Purpose: Remove office-related packages from Debian PXE client

echo "[i] Removing office applications..."

apt purge -y libreoffice* \
  abiword \
  gnumeric \
  evince \
  okular \
  atril \
  gedit \
  scribus \
  thunderbird \
  hunspell* \
  mythes* \
  hyphen* \
  xpdf \
  qpdfview

apt autoremove -y
apt clean

echo "[✓] Office applications removed successfully."
