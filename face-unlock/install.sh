#!/bin/bash
# Face unlock with the IR camera (Howdy) for the Omarchy lock screen, polkit and sudo.
# Needs: camera-ir/ installed (and rebooted), Howdy from the AUR (yay -S howdy), quickshell (Omarchy).
# Run: sudo ./install.sh, then enrol (command printed at the end).   Undo: sudo ./uninstall.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd)
HOWDY=/usr/lib/security/howdy
[ -f "$HOWDY/compare.py" ] || { echo "Howdy not found: install it first (yay -S howdy)"; exit 1; }
modinfo vd55g0 >/dev/null 2>&1 || { echo "IR camera driver missing: install camera-ir/ first"; exit 1; }
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

step "Programs"
install -D -m 755 "$D/bin/faceauthd" /usr/local/lib/surface-faceauth/faceauthd
install -D -m 755 "$D/bin/surface-faceauth-client" /usr/local/bin/surface-faceauth-client
install -D -m 755 "$D/bin/surface-ir-bridge" /usr/local/bin/surface-ir-bridge
install -D -m 755 "$D/bin/fprintd-list" /usr/local/bin/fprintd-list   # lock-screen shim, see README

step "Toast (uses Omarchy's own notification style modules)"
T=/usr/local/lib/surface-faceauth/toast
install -D -m 644 "$D/toast/shell.qml" "$T/shell.qml"
ln -sfn /usr/share/omarchy/shell/Commons "$T/Commons"
ln -sfn /usr/share/omarchy/shell/Ui "$T/Ui"

step "Daemon"
install -D -m 644 "$D/systemd/surface-faceauthd.service" /etc/systemd/system/surface-faceauthd.service
systemctl daemon-reload
systemctl enable surface-faceauthd.service
systemctl restart surface-faceauthd.service

step "Howdy: read the IR virtual webcam; accept dark IR backgrounds"
cp -n "$HOWDY/config.ini" "$HOWDY/config.ini.orig"
sed -i -E 's|^device_path = .*|device_path = /dev/video51|; s|^dark_threshold = .*|dark_threshold = 90|' "$HOWDY/config.ini"

step "PAM"
cp -n /etc/pam.d/sudo /etc/pam.d/sudo.before-faceauth
sed -i '\|surface-faceauth|d' /etc/pam.d/sudo
tac "$D/pam/sudo-lines" | while IFS= read -r l; do sed -i "1i $l" /etc/pam.d/sudo; done
install -m 644 "$D/pam/polkit-1" /etc/pam.d/polkit-1
install -m 644 "$D/pam/omarchy-lock-fingerprint" /etc/pam.d/omarchy-lock-fingerprint
head -3 /etc/pam.d/sudo

U="${SUDO_USER:-$USER}"
printf '\n\033[1;32mInstalled.\033[0m Enrol your face (look at the screen):\n'
echo "  sudo bash -c 'surface-ir-bridge start 60; howdy -U $U add; surface-ir-bridge stop'"
