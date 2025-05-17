#!/bin/bash

# === PXE ISO Recovery Script ===
# Recovers chroot, squashfs, and PXE boot files from a customized ISO
# Author: examshield recovery assistant

# Configurable Paths
ISO_NAME="debian-secure-v9.iso"
WORKDIR="$HOME/debian-custom1"
ISOMOUNT="$HOME/iso-mount"

# Step 1: Mount the ISO
echo "[+] Mounting ISO..."
mkdir -p "$ISOMOUNT"
sudo mount -o loop "$HOME/$ISO_NAME" "$ISOMOUNT" || { echo "[!] Failed to mount ISO"; exit 1; }

# Step 2: Extract filesystem.squashfs
echo "[+] Copying filesystem.squashfs..."
mkdir -p "$WORKDIR"
cp "$ISOMOUNT/live/filesystem.squashfs" "$WORKDIR/"

# Step 3: Unsquash into chroot/
echo "[+] Unsquashing to chroot/..."
cd "$WORKDIR"
sudo unsquashfs filesystem.squashfs
mv squashfs-root chroot

# Step 4: Recreate squashfs folder
echo "[+] Preparing squashfs folder..."
mkdir -p "$WORKDIR/squashfs"

# Step 5: Extract kernel and initrd
echo "[+] Copying kernel and initrd.img to /srv/tftp..."
sudo cp chroot/boot/vmlinuz-* /srv/tftp/debian/vmlinuz
sudo cp chroot/boot/initrd.img-* /srv/tftp/debian/initrd.img

# Step 6: Rebuild filesystem.squashfs
echo "[+] Rebuilding squashfs image..."
sudo mksquashfs chroot squashfs/filesystem.squashfs -e boot

# Step 7: Copy squashfs to Apache directory
echo "[+] Copying squashfs to /var/www/html/debian/live/..."
sudo mkdir -p /var/www/html/debian/live
sudo cp squashfs/filesystem.squashfs /var/www/html/debian/live/

# Step 8: Restart PXE services
echo "[+] Restarting Apache and TFTP services..."
sudo systemctl restart apache2
sudo systemctl restart tftpd-hpa

# Step 9: Cleanup
sudo umount "$ISOMOUNT"
echo "[✓] PXE ISO recovery complete. Ready to boot PXE clients."
