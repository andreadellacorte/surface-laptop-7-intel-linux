#!/bin/bash
# Remove the patched audio module. Run: sudo ./uninstall.sh
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
dkms remove sl7-audio/1.0 --all
rm -rf /usr/src/sl7-audio-1.0
limine-mkinitcpio
echo "Removed. Reboot to go back to the stock module."
