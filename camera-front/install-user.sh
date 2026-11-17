#!/bin/bash
# Per-user part: bridge (libcamera -> /dev/video50) started on demand, and a Monologue
# launcher that starts/stops it. Run as your user (not root).
set -euo pipefail
[ "$(id -u)" != 0 ] || { echo "run as your user, not root"; exit 1; }
D=$(cd "$(dirname "$0")" && pwd)
install -D -m 755 "$D/user/surface-camera-bridge" ~/.local/bin/surface-camera-bridge
install -D -m 755 "$D/user/monologue-camera" ~/.local/bin/monologue-camera
install -D -m 644 "$D/user/surface-camera.service" ~/.config/systemd/user/surface-camera.service
systemctl --user daemon-reload
if [ -f /usr/share/applications/monologue.desktop ]; then
  mkdir -p ~/.local/share/applications
  sed "s|^Exec=monologue|Exec=$HOME/.local/bin/monologue-camera|" /usr/share/applications/monologue.desktop \
    > ~/.local/share/applications/monologue.desktop
  echo "Monologue launcher updated: pick 'Surface Camera' in its camera list."
fi
echo "Other V4L2 apps: systemctl --user start surface-camera, then use 'Surface Camera'."
