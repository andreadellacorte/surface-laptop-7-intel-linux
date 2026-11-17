#!/bin/bash
# Install the patched Surface registry module permanently via DKMS and rebuild the boot images.
# Run with: sudo ./install.sh      Undo: sudo ./uninstall.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd); V=1.0; K=$(uname -r)

pacman -S --needed --noconfirm dkms linux-omarchy-headers
echo "== registering DKMS module sl7-sam/$V =="
dkms remove sl7-sam/$V --all >/dev/null 2>&1 || true
rm -rf /usr/src/sl7-sam-$V && cp -r "$D/dkms" /usr/src/sl7-sam-$V
dkms add sl7-sam/$V
dkms install sl7-sam/$V -k "$K" --force

echo "== check: module that will load =="
F=$(modinfo -n surface_aggregator_registry); echo "$F"
modinfo surface_aggregator_registry | grep -q 'MSHW0005' && echo "OK: patched module is active" \
  || { echo "ERROR: stock module still preferred"; exit 1; }

echo "== rebuilding boot images (includes the module, loaded early) =="
limine-mkinitcpio
echo "Done. Reboot to confirm the keyboard works at the login screen."
