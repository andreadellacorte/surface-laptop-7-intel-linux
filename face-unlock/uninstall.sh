#!/bin/bash
# Remove face unlock: password-only everywhere again. Run: sudo ./uninstall.sh
# (Howdy itself and your face model stay; remove with: sudo howdy -U <user> clear; yay -R howdy)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
sed -i '\|surface-faceauth|d' /etc/pam.d/sudo
rm -f /etc/pam.d/polkit-1 /etc/pam.d/omarchy-lock-fingerprint
systemctl disable --now surface-faceauthd.service 2>/dev/null || true
rm -f /etc/systemd/system/surface-faceauthd.service; systemctl daemon-reload
rm -rf /usr/local/lib/surface-faceauth
rm -f /usr/local/bin/surface-faceauth-client /usr/local/bin/surface-ir-bridge /usr/local/bin/fprintd-list
[ -f /usr/lib/security/howdy/config.ini.orig ] && cp /usr/lib/security/howdy/config.ini.orig /usr/lib/security/howdy/config.ini
echo "Face unlock removed."
