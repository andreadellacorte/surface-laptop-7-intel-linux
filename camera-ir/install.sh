#!/bin/bash
# IR camera (ST VD55G0, ACPI SMO55F0) + IR flood emitter: vd55g0 driver and patched ipu-bridge via DKMS.
# Needs camera-front/ installed first (libcamera + the /dev/video51 virtual webcam).
# Run: sudo ./install.sh, then REBOOT (ipu-bridge must be loaded at boot, not swapped live).
# Undo: sudo ./uninstall.sh (and reboot)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd); V=1.0
[ -f /etc/modprobe.d/sl7-camera-loopback.conf ] || { echo "install camera-front/ first"; exit 1; }
rm -rf /usr/src/sl7-ir-$V && cp -r "$D/dkms" /usr/src/sl7-ir-$V
dkms remove sl7-ir/$V --all >/dev/null 2>&1 || true
dkms install sl7-ir/$V
depmod -a "$(uname -r)"
echo "vd55g0:     $(modinfo -n vd55g0)"
echo "ipu_bridge: $(modinfo -n ipu_bridge)"
echo "Done. Reboot, then test with: cam -l   (expect a second camera 'vd55g0')"
