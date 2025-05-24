# Define variables
ISO_FILE="debian-live-12.5.0-amd64-xfce.iso"
CUSTOM_DIR="debian-custom4"
CHROOT_DIR="$CUSTOM_DIR/chroot"

# Create directories
mkdir -p "$CUSTOM_DIR/iso"
mkdir -p "$CUSTOM_DIR/mount"
mkdir -p "$CHROOT_DIR"

# Mount the ISO
sudo mount -o loop "$ISO_FILE" "$CUSTOM_DIR/mount"

# Copy ISO contents
rsync -a "$CUSTOM_DIR/mount/" "$CUSTOM_DIR/iso/"
sudo unsquashfs -d "$CHROOT_DIR" "$CUSTOM_DIR/iso/live/filesystem.squashfs"

# Unmount ISO
sudo umount "$CUSTOM_DIR/mount"
