#!/bin/bash
# PXE Server Setup Script – Ubuntu Server
# Sets up DHCP, TFTP (/srv/tftp), Apache – No OS boot files copied yet

set -euo pipefail

### Variables – change as needed ###
IFACE="enp0s3"
PXE_IP="192.168.0.101"
CIDR="24"
GATEWAY="192.168.0.1"
DNS="8.8.8.8"

SUBNET="192.168.0.0"
RANGE_START="192.168.0.50"
RANGE_END="192.168.0.80"

TFTP_DIR="/srv/tftp"
HTTP_DIR="/var/www/html"
LIVE_SUBDIR="debian/live"
#####################################

echo "[1] Updating and installing required packages…"
apt-get update
apt-get install -y isc-dhcp-server tftpd-hpa syslinux-common apache2 net-tools

echo "[2] Configuring static IP with netplan…"
cat > /etc/netplan/01-pxe-static.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: no
      addresses: [$PXE_IP/$CIDR]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF

netplan apply

echo "[3] Configuring DHCP server…"
cat > /etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet $SUBNET netmask 255.255.255.0 {
  range $RANGE_START $RANGE_END;
  option routers $GATEWAY;
  option broadcast-address ${SUBNET%.*}.255;
  filename "pxelinux.0";
  next-server $PXE_IP;
}
EOF

sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"$IFACE\"/" /etc/default/isc-dhcp-server
systemctl enable --now isc-dhcp-server

echo "[4] Setting up TFTP server at $TFTP_DIR…"
mkdir -p "$TFTP_DIR/pxelinux.cfg"
cp /usr/lib/PXELINUX/pxelinux.0 "$TFTP_DIR/"
cp /usr/lib/syslinux/modules/bios/"menu.c32" "$TFTP_DIR/" || true

cat > /etc/default/tftpd-hpa <<EOF
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="$TFTP_DIR"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF

systemctl enable --now tftpd-hpa

echo "[5] Creating basic PXE menu config…"
cat > "$TFTP_DIR/pxelinux.cfg/default" <<EOF
DEFAULT menu.c32
PROMPT 0
TIMEOUT 30
ONTIMEOUT local

LABEL Placeholder
  MENU LABEL Boot Placeholder
  KERNEL debian/live/vmlinuz
  APPEND initrd=debian/live/initrd.img boot=live fetch=http://$PXE_IP/$LIVE_SUBDIR/filesystem.squashfs

LABEL local
  MENU LABEL Boot from local disk
  LOCALBOOT 0
EOF

echo "[6] Preparing Apache root at $HTTP_DIR/$LIVE_SUBDIR (empty for now)…"
mkdir -p "$HTTP_DIR/$LIVE_SUBDIR"
chmod -R 755 "$HTTP_DIR/$LIVE_SUBDIR"

systemctl enable --now apache2

echo "[✓] PXE server installed."
echo "Next steps:"
echo "→ Place 'vmlinuz', 'initrd.img', and 'filesystem.squashfs' into $HTTP_DIR/$LIVE_SUBDIR"
echo "→ Restart Apache if needed: systemctl restart apache2"
echo "→ Boot PXE client to test DHCP + TFTP response"
