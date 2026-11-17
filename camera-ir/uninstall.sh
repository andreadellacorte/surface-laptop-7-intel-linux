#!/bin/bash
# Remove the IR camera driver. Run: sudo ./uninstall.sh, then reboot.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
dkms remove sl7-ir/1.0 --all 2>/dev/null || true
rm -rf /usr/src/sl7-ir-1.0
depmod -a "$(uname -r)"
echo "Removed. Reboot to go back to the stock ipu-bridge."
