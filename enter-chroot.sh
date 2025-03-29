#!/bin/bash

# Set your working directory
CHROOT_DIR=~/squashfs-root

#dont use sudo in below mount commands if you have logged inas root user
echo "🔧 Mounting system directories..."
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount --bind /proc "$CHROOT_DIR/proc"
mount --bind /sys "$CHROOT_DIR/sys"

echo "✅ Mounted successfully. Entering chroot..."
chroot "$CHROOT_DIR"
