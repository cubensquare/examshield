#!/bin/bash

# ===============================
# Exits and unmounts chroot
# Rebuilds filesystem.squashfs
# Rebuilds the custom Debian ISO
# Copies updated files to PXE server paths (/srv/tftp/debian/ and /var/www/html/debian/live/)
# ===============================

# ===============================
# CONFIGURABLE PATHS
# ===============================
CHROOT_DIR=~/squashfs-root
CUSTOM_DIR=~/debian-custom1
ISO_OUTPUT=~/debian-secure.iso
PXE_TFTP_DIR=/srv/tftp/debian
PXE_HTTP_LIVE_DIR=/var/www/html/debian/live

echo "🚪 [1] Unmounting chroot..."
sudo umount -lf "$CHROOT_DIR/dev/pts"
sudo umount -lf "$CHROOT_DIR/dev"
sudo umount -lf "$CHROOT_DIR/proc"
sudo umount -lf "$CHROOT_DIR/sys"

echo "🧹 [2] Cleaning old squashfs..."
sudo rm -f "$CUSTOM_DIR/live/filesystem.squashfs"

echo "📦 [3] Rebuilding filesystem.squashfs..."
sudo mksquashfs "$CHROOT_DIR" "$CUSTOM_DIR/live/filesystem.squashfs" -comp xz -e boot

echo "💿 [4] Rebuilding the ISO image..."
cd "$CUSTOM_DIR"
sudo xorriso -as mkisofs -o "$ISO_OUTPUT" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat .

echo "🚀 [5] Syncing files to PXE server paths..."

# Create target folders if not exist
sudo mkdir -p "$PXE_TFTP_DIR"
sudo mkdir -p "$PXE_HTTP_LIVE_DIR"

# Copy vmlinuz and initrd (only if modified – optional override)
echo "    - Copying vmlinuz and initrd.img..."
sudo cp "$CUSTOM_DIR/live/vmlinuz" "$PXE_TFTP_DIR/vmlinuz"
sudo cp "$CUSTOM_DIR/live/initrd.img" "$PXE_TFTP_DIR/initrd"

# Copy new squashfs to PXE HTTP directory
echo "    - Copying new filesystem.squashfs..."
sudo cp "$CUSTOM_DIR/live/filesystem.squashfs" "$PXE_HTTP_LIVE_DIR/"

echo "✅ All done! PXE server now has updated squashfs and boot files."
echo "📎 Final ISO: $ISO_OUTPUT"
