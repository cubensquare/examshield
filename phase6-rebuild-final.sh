#!/bin/bash

echo "[INFO] Phase 6: Rebuilding Filesystem and Final ISO..."

# Exit on error
set -e

### 🔁 Paths (Change if your structure is different)
SQUASHFS_DIR=~/squashfs-root
CUSTOM_ISO_DIR=~/debian-custom
TFTP_DIR=/srv/tftp/debian
HTTP_DIR=/var/www/html/debian/live

### STEP 1: Clean old squashfs
echo "[INFO] Cleaning old filesystem.squashfs..."
rm -f ${CUSTOM_ISO_DIR}/live/filesystem.squashfs

### STEP 2: Repack filesystem.squashfs
echo "[INFO] Repacking filesystem.squashfs..."
sudo mksquashfs ${SQUASHFS_DIR} ${CUSTOM_ISO_DIR}/live/filesystem.squashfs -comp xz -e boot

### STEP 3: Rebuild ISO
echo "[INFO] Rebuilding debian-secure.iso..."
cd ${CUSTOM_ISO_DIR}
sudo xorriso -as mkisofs -o debian-secure.iso \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat .

echo "[INFO] ISO successfully rebuilt: ${CUSTOM_ISO_DIR}/debian-secure.iso"

### STEP 4: Copy boot files to PXE directories
echo "[INFO] Copying initrd and vmlinuz to PXE TFTP folder..."
sudo cp ${CUSTOM_ISO_DIR}/live/initrd.img ${TFTP_DIR}/initrd
sudo cp ${CUSTOM_ISO_DIR}/live/vmlinuz ${TFTP_DIR}/vmlinuz

echo "[INFO] Copying filesystem.squashfs to HTTP share..."
sudo cp ${CUSTOM_ISO_DIR}/live/filesystem.squashfs ${HTTP_DIR}/

### STEP 5: Restart Services
echo "[INFO] Restarting apache2 and tftpd-hpa..."
sudo systemctl restart apache2
sudo systemctl restart tftpd-hpa

echo "[✅ SUCCESS] Final ISO ready. PXE boot client to test your secure OS!"
