#!/bin/bash

### PXE Server ISO Builder Script ###
# Version: v1
# Purpose: Automate building a portable PXE Server ISO from Ubuntu 24.04 base

set -e

### VARIABLES ###
VERSION="v1"
ISO_NAME="pxe-server-customer-iso-${VERSION}"
WORKDIR="$HOME/${ISO_NAME}"
CHROOTDIR="${WORKDIR}/chroot"
ISODIR="${WORKDIR}/iso"

### STEP 1: PREPARE DIRECTORIES ###
echo "[+] Creating working directories..."
mkdir -p ${CHROOTDIR} ${ISODIR}/{casper,boot/grub,isolinux} ${WORKDIR}/scratch

### STEP 2: INSTALL REQUIRED TOOLS ###
echo "[+] Installing build tools..."
sudo apt update
sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin isolinux syslinux-utils

### STEP 3: DEBOOTSTRAP MINIMAL UBUNTU BASE ###
echo "[+] Bootstrapping minimal Ubuntu system into chroot..."
sudo debootstrap --arch=amd64 noble ${CHROOTDIR} http://archive.ubuntu.com/ubuntu/

### STEP 4: CONFIGURE PXE SERVER ENVIRONMENT ###
echo "[+] Binding /dev into chroot and entering..."
sudo mount --bind /dev ${CHROOTDIR}/dev

cat <<'EOF' | sudo chroot ${CHROOTDIR} /bin/bash
  set -e
  echo "[chroot] Updating and installing PXE services..."
  apt update
  DEBIAN_FRONTEND=noninteractive apt install -y apache2 tftpd-hpa nfs-kernel-server isc-dhcp-server net-tools systemd-sysv

  echo "[chroot] Creating service enablement..."
  systemctl enable apache2
  systemctl enable tftpd-hpa
  systemctl enable isc-dhcp-server

  echo "[chroot] PXE chroot setup complete. You may copy PXE configs manually if needed."
  exit
EOF

sudo umount ${CHROOTDIR}/dev

### STEP 5: CREATE SQUASHFS ###
echo "[+] Creating squashfs from chroot..."
sudo mksquashfs ${CHROOTDIR} ${ISODIR}/casper/filesystem.squashfs -comp xz

### STEP 6: COPY KERNEL & INITRD ###
echo "[+] Copying kernel and initrd..."
sudo cp ${CHROOTDIR}/boot/vmlinuz* ${ISODIR}/casper/vmlinuz
sudo cp ${CHROOTDIR}/boot/initrd.img* ${ISODIR}/casper/initrd

### STEP 7: CONFIGURE ISOLINUX (BIOS) ###
echo "[+] Setting up ISOLINUX for BIOS boot..."
cp /usr/lib/ISOLINUX/isolinux.bin ${ISODIR}/isolinux/
cp /usr/lib/syslinux/modules/bios/* ${ISODIR}/isolinux/

cat <<EOF > ${ISODIR}/isolinux/isolinux.cfg
UI menu.c32
PROMPT 0
MENU TITLE PXE Server ISO Boot Menu
TIMEOUT 50

LABEL live
  menu label ^Start PXE Server
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---
EOF

### STEP 8: CONFIGURE GRUB (UEFI) ###
echo "[+] Creating GRUB config for UEFI..."
cat <<EOF > ${ISODIR}/boot/grub/grub.cfg
set timeout=10
menuentry "Start PXE Server (Live)" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}
EOF

### STEP 9: BUILD ISO ###
echo "[+] Building ISO..."
cd ${ISODIR}
sudo xorriso -as mkisofs \
  -iso-level 3 -o ../${ISO_NAME}.iso \
  -full-iso9660-filenames \
  -volid "PXE_SERVER" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat .

cd ~
echo "✅ ISO Created: ${WORKDIR}/${ISO_NAME}.iso"
echo "🎯 You can now flash this ISO to USB or share with client to boot PXE Server."

exit 0
