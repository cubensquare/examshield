#!/bin/bash

echo "[i] Removing man pages, docs, locales..."

# Remove locales except en
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name "en*" -exec rm -rf {} +

# Remove man pages and documentation
rm -rf /usr/share/man/*
rm -rf /usr/share/doc/*
rm -rf /usr/share/info/*
rm -rf /usr/share/help/*
rm -rf /usr/share/gnome/help/*

# Strip debug symbols from binaries (optional)
strip --strip-unneeded /usr/bin/* || true
strip --strip-unneeded /usr/lib/* || true

# Clean cache
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/*
rm -rf /tmp/*
rm -rf /usr/share/fonts/* && apt-get install -y fonts-dejavu-core
