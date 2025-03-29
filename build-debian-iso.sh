 #!/bin/bash

CHROOT_DIR=~/squashfs-root
CUSTOM_DIR=~/debian-custom1
ISO_OUTPUT=~/debian-secure.iso

echo "🚪 Exiting chroot and unmounting..."
sudo umount -lf "$CHROOT_DIR/dev/pts"
sudo umount -lf "$CHROOT_DIR/dev"
sudo umount -lf "$CHROOT_DIR/proc"
sudo umount -lf "$CHROOT_DIR/sys"

echo "🧹 Cleaning old squashfs (if exists)..."
sudo rm -f "$CUSTOM_DIR/live/filesystem.squashfs"

echo "📦 Rebuilding squashfs filesystem..."
sudo mksquashfs "$CHROOT_DIR" "$CUSTOM_DIR/live/filesystem.squashfs" -comp xz -e boot

echo "🔥 Building final ISO image..."
cd "$CUSTOM_DIR"
sudo xorriso -as mkisofs -o "$ISO_OUTPUT" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat .

echo "✅ ISO rebuilt successfully: $ISO_OUTPUT"
