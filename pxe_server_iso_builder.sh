#!/bin/bash

# Clone current PXE Server into a bootable ISO image
# Author: Goms | CubenSquare
# Version: v1
# Target: Clone Ubuntu 24.04 PXE Server (Live Server) as-is

set -e

### CONFIGURATION ###
VERSION="v1"
ISO_NAME="pxe-server-clone-${VERSION}.iso"
WORKDIR="$HOME/pxe-server-clone-${VERSION}"
EXCLUDE_LIST="$WORKDIR/exclude.txt"

echo "[+] Creating working directory: $WORKDIR"
mkdir -p "$WORKDIR"

### STEP 1: CREATE RSYNC EXCLUDE LIST ###
cat <<EOF > "$EXCLUDE_LIST"
/proc/*
/sys/*
/dev/*
/tmp/*
/run/*
/mnt/*
/media/*
/lost+found/*
/swapfile
EOF

### STEP 2: COPY CURRENT SYSTEM ###
echo "[+] Copying PXE server filesystem using rsync..."
sudo rsync -aAXv / "$WORKDIR/rootfs" --exclude-from="$EXCLUDE_LIST"

### STEP 3: PREPARE ISO BOOT STRUCTURE ###
echo "[+] Creating bootable ISO structure..."
mkdir -p "$WORKDIR/iso/boot/grub"

# Copy kernel and initrd from current system
cp /boot/vmlinuz* "$WORKDIR/iso/vmlinuz"
cp /boot/initrd.img* "$WORKDIR/iso/initrd"

# Create GRUB config
cat <<EOF > "$WORKDIR/iso/boot/grub/grub.cfg"
set timeout=5
menuentry "Boot PXE Server Clone" {
    linux /vmlinuz root=/dev/ram0 ramdisk_size=1500000 root=/rootfs boot=live toram=filesystem.squashfs
    initrd /initrd
}
EOF

### STEP 4: CREATE SQUASHFS ###
echo "[+] Creating squashfs of root filesystem..."
mksquashfs "$WORKDIR/rootfs" "$WORKDIR/iso/filesystem.squashfs" -comp xz -e boot

### STEP 5: BUILD ISO ###
echo "[+] Building ISO using xorriso..."
xorriso -as mkisofs \
  -o "$ISO_NAME" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c boot.cat -b boot/grub/grub.cfg \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/grub.cfg \
  -no-emul-boot -isohybrid-gpt-basdat \
  "$WORKDIR/iso"

### DONE ###
echo "✅ PXE Server ISO created: $ISO_NAME"
echo "📁 Location: $PWD/$ISO_NAME"
echo "💡 Flash this ISO using BalenaEtcher, dd, or Rufus to boot the PXE server elsewhere."
