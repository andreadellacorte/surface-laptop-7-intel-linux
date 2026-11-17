#!/bin/bash
# Remove everything install.sh put in place. Run with: sudo ./uninstall.sh
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
systemctl stop 'iptsd@*.service' 2>/dev/null
systemctl disable iptsd-resume.service 2>/dev/null
rm -f /usr/local/bin/iptsd /usr/local/bin/iptsd-calibrate /usr/local/bin/iptsd-check-device \
      /usr/local/bin/iptsd-dump /usr/local/bin/iptsd-perf /usr/local/bin/iptsd-replay \
      /usr/lib/udev/rules.d/50-iptsd.rules /usr/lib/systemd/system/iptsd@.service \
      /usr/lib/systemd/system-sleep/iptsd /etc/systemd/system/iptsd-resume.service \
      /etc/iptsd.d/99-surface-laptop-7-touchpad.conf /etc/libinput/local-overrides.quirks
rm -rf /usr/local/share/iptsd
rmdir /etc/iptsd.d 2>/dev/null
systemctl daemon-reload; udevadm control --reload
echo "iptsd removed (touchpad returns to mouse mode after a reboot or driver rebind)"
