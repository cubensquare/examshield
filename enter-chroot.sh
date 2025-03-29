#!/bin/bash

# Set your working directory
CHROOT_DIR=~/squashfs-root

echo "🔧 Mounting system directories..."
sudo mount --bind /dev "$CHROOT_DIR/dev"
sudo mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
sudo mount --bind /proc "$CHROOT_DIR/proc"
sudo mount --bind /sys "$CHROOT_DIR/sys"

echo "✅ Mounted successfully. Entering chroot..."
sudo chroot "$CHROOT_DIR" /bin/bash
