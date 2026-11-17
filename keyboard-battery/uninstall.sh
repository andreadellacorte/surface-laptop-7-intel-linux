#!/bin/bash
# Remove the DKMS module and rebuild boot images with the stock module.
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
dkms remove sl7-sam/1.0 --all
rm -rf /usr/src/sl7-sam-1.0
limine-mkinitcpio
echo "Removed. The built-in keyboard will stop working after reboot."
