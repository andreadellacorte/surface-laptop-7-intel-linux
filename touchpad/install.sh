#!/bin/bash
# Install the patched iptsd (Surface Laptop 7 Intel haptic touchpad) built by ./build.sh (in ./src/build).
# Run with: sudo ./install.sh      Undo with: sudo ./uninstall.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd)

echo "== installing iptsd binaries, udev rule, systemd units =="
meson install -C "$D/src/build" --no-rebuild --skip-subprojects >/dev/null

echo "== installing Surface Laptop 7 config, palm-rejection quirk, resume restart =="
install -D -m 644 "$D/99-surface-laptop-7-touchpad.conf" /etc/iptsd.d/99-surface-laptop-7-touchpad.conf
install -D -m 644 "$D/local-overrides.quirks" /etc/libinput/local-overrides.quirks
install -D -m 644 "$D/iptsd-resume.service" /etc/systemd/system/iptsd-resume.service

systemctl daemon-reload
systemctl enable iptsd-resume.service >/dev/null 2>&1
udevadm control --reload
udevadm trigger --action=add --subsystem-match=hidraw
sleep 2

echo "== status =="
systemctl list-units --plain --no-legend 'iptsd@*.service' || true
grep -q 'IPTSD Virtual Touchpad' /proc/bus/input/devices \
  && echo "OK: IPTSD Virtual Touchpad present - try two-finger scrolling" \
  || echo "iptsd virtual touchpad NOT present - check: journalctl -b -u 'iptsd@*'"
