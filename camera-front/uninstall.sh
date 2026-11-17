#!/bin/bash
# Remove the front-camera fix. Run: sudo ./uninstall.sh  (and as your user:
#   rm ~/.local/bin/{surface-camera-bridge,monologue-camera} ~/.config/systemd/user/surface-camera.service
#      ~/.local/share/applications/monologue.desktop)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
dkms remove sl7-camera/1.0 --all 2>/dev/null || true
rm -rf /usr/src/sl7-camera-1.0
rm -f /etc/modprobe.d/sl7-camera-loopback.conf /etc/modules-load.d/sl7-camera-loopback.conf
echo "Removed. Reboot to load the stock ov02c10 driver."
