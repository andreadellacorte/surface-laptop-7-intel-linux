#!/bin/bash
# Install the patched snd-soc-sdw-utils via DKMS. Run: sudo ./install.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd); V=1.0; K=$(uname -r)
dkms remove sl7-audio/$V --all >/dev/null 2>&1 || true
rm -rf /usr/src/sl7-audio-$V && cp -r "$D/dkms" /usr/src/sl7-audio-$V
dkms add sl7-audio/$V
dkms install sl7-audio/$V -k "$K" --force
F=$(modinfo -n snd_soc_sdw_utils); echo "$F"
case "$F" in
  */updates/dkms/*) echo "OK: patched audio module is active" ;;
  *) echo "ERROR: stock module still preferred"; exit 1 ;;
esac
limine-mkinitcpio
echo "Done. Reboot to get sound."
