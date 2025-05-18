#!/bin/bash

# === Define variables ===
CHROOT_DIR="$HOME/squashfs-root"
CUSTOM_DIR="$HOME/debian-custom"
LIVE_DIR="$CUSTOM_DIR/live"
ISO_OUTPUT="$HOME/debian-secure-v1-1.iso"
PXE_TFTP_DIR="/srv/tftp/debian"
PXE_HTTP_DIR="/var/www/html/debian/live"

echo "[i] Unmounting previously bound directories..."
for mnt in dev/pts dev proc sys run; do
  if mount | grep -q "$CHROOT_DIR/$mnt"; then
    umount "$CHROOT_DIR/$mnt"
    sleep 1
  fi
done

echo "[i] Cleaning up old squashfs ..."
rm -f "$LIVE_DIR/filesystem.squashfs"

echo "[i] Rebuilding filesystem.squashfs from chroot..."
mksquashfs "$CHROOT_DIR" "$LIVE_DIR/filesystem.squashfs" -comp xz -e boot

echo "[✓] squashfs built: $LIVE_DIR/filesystem.squashfs"

echo "[i] Building final ISO..."
xorriso -as mkisofs \
  -o "$ISO_OUTPUT" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -iso-level 3 \
  -volid "DebianSecure" \
  "$CUSTOM_DIR"

echo "[✓] ISO created: $ISO_OUTPUT"

echo "[i] Preparing PXE directories..."
mkdir -p "$PXE_TFTP_DIR"
mkdir -p "$PXE_HTTP_DIR"

mount -o loop "$ISO_OUTPUT" /mnt/iso
cp /mnt/iso/live/vmlinuz "$PXE_TFTP_DIR/"
cp /mnt/iso/live/initrd.img "$PXE_TFTP_DIR/"
cp /mnt/iso/live/filesystem.squashfs "$PXE_HTTP_DIR/"
umount /mnt/iso

echo "[i] Restarting Apache and TFTP services..."
systemctl restart apache2
systemctl restart tftpd-hpa

echo "[✓] PXE server is ready. Boot your PXE clients now."
