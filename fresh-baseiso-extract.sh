#!/usr/bin/env bash
# ------------------------------------------------------------------
# fresh_base_iso_extract.sh
#   • Extract Debian Live ISO for PXE use
#   • Prepare writable chroot
#   • Publish kernel + initrd + squashfs to HTTP/TFTP root
#
# Usage:
#   sudo ./fresh_base_iso_extract.sh
# ------------------------------------------------------------------

set -euo pipefail

# --------- EDIT THESE THREE VARIABLES --------------------------------
ISO_FILE="$HOME/debian-live-12.5.0-amd64-xfce.iso"
WORKROOT="$HOME/pxe-build"           # all temp work under this dir
WEBROOT="/srv/www/html/debian/live"  # folder served by Apache/Nginx/TFTP
# ---------------------------------------------------------------------

ISO_MNT="$WORKROOT/iso-mnt"
ISO_COPY="$WORKROOT/iso-copy"
SQUASH_DIR="$WORKROOT/squashfs"
CHROOT_DIR="$WORKROOT/chroot"

# 1) sanity-check ISO file
[[ -f "$ISO_FILE" ]] || { echo "❌ ISO not found: $ISO_FILE"; exit 1; }

# 2) create directories
echo "🗂  Creating work folders …"
sudo mkdir -p "$ISO_MNT" "$ISO_COPY" "$SQUASH_DIR" "$CHROOT_DIR" "$WEBROOT"

# 3) mount ISO
echo "🔗 Mounting ISO → $ISO_MNT"
sudo mount -o loop "$ISO_FILE" "$ISO_MNT"

# 4) copy ISO contents
echo "📥 Copying ISO → $ISO_COPY (rsync)…"
sudo rsync -a --delete "$ISO_MNT"/ "$ISO_COPY"/

# 5) unmount ISO & clean mount dir
sudo umount "$ISO_MNT"
sudo rmdir  "$ISO_MNT"

# 6) unsquash filesystem
echo "📦 Unsquashing filesystem.squashfs …"
sudo unsquashfs -d "$SQUASH_DIR" "$ISO_COPY/live/filesystem.squashfs"

# 7) copy into writable chroot
echo "📋 Copying squashfs tree → $CHROOT_DIR …"
sudo cp -a "$SQUASH_DIR"/. "$CHROOT_DIR"/

# 8) publish vmlinuz, initrd, squashfs to WEBROOT
echo "🚀 Publishing PXE boot files to $WEBROOT …"
sudo cp "$ISO_COPY"/live/vmlinuz* "$WEBROOT/vmlinuz"
sudo cp "$ISO_COPY"/live/initrd*  "$WEBROOT/initrd"
sudo cp "$ISO_COPY/live/filesystem.squashfs" "$WEBROOT/"

echo
echo "✅ Finished."
echo "   • Writable chroot: $CHROOT_DIR"
echo "   • PXE files now in: $WEBROOT"
echo
echo "👉  To customise:"
echo "     sudo mount --bind /dev  $CHROOT_DIR/dev"
echo "     sudo mount --bind /proc $CHROOT_DIR/proc"
echo "     sudo chroot $CHROOT_DIR /bin/bash"
