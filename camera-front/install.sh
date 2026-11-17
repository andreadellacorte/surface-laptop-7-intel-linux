#!/bin/bash
# Front camera (OV02C10): patched driver via DKMS + virtual webcams for V4L2-only apps.
# Run: sudo ./install.sh    then (as your user) ./install-user.sh    Undo: sudo ./uninstall.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd); V=1.0

echo "== packages =="
pacman -S --needed --noconfirm libcamera libcamera-tools pipewire-libcamera \
  gst-plugin-libcamera gst-plugins-base gst-plugins-good v4l2loopback-dkms v4l2loopback-utils dkms

echo "== DKMS module sl7-camera (ov02c10 that accepts the 12 MHz clock) =="
rm -rf /usr/src/sl7-camera-$V && cp -r "$D/dkms" /usr/src/sl7-camera-$V
dkms remove sl7-camera/$V --all >/dev/null 2>&1 || true
dkms install sl7-camera/$V

echo "== virtual webcams: /dev/video50 (front), /dev/video51 (IR, see camera-ir/) =="
cat > /etc/modprobe.d/sl7-camera-loopback.conf <<'CONF'
# Virtual webcams fed from libcamera: front camera (video50) and IR camera (video51)
options v4l2loopback devices=2 video_nr=50,51 card_label="Surface Camera,Surface IR Camera" exclusive_caps=1,1 max_buffers=2
CONF
echo v4l2loopback > /etc/modules-load.d/sl7-camera-loopback.conf
modprobe -r v4l2loopback 2>/dev/null || true; modprobe v4l2loopback
modprobe -r ov02c10 2>/dev/null || true; modprobe ov02c10
echo "ov02c10: $(modinfo -n ov02c10)"
echo "Done. Next, as your user: ./install-user.sh   (test with: cam -l)"
