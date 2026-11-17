#!/bin/bash
# Build the patched iptsd for the Surface Laptop 7 (Intel) touchpad. Run as your user:
#   sudo pacman -S --needed meson ninja cmake cli11 eigen microsoft-gsl
#   ./build.sh && sudo ./install.sh
set -euo pipefail
D=$(cd "$(dirname "$0")" && pwd)
REPO=https://github.com/alex-lentz/iptsd.git
BASE=3663e96e758145801c3cb1ce7c72f362d0d4a5f5   # tested base commit of the fork

[ -d "$D/src/.git" ] || git clone "$REPO" "$D/src"
cd "$D/src"
git fetch -q origin
git checkout -q -B sl7 "$BASE"
git -c user.name=sl7-build -c user.email=sl7-build@localhost am -q "$D"/patches/*.patch

OPTS=(--buildtype=release --prefix=/usr/local -Dsample_config=false -Dwerror=false
      -Ddebug_tools=calibrate,dump,perf --force-fallback-for=fmt,spdlog,inih)
if [ -d build ]; then meson setup --reconfigure build "${OPTS[@]}"; else meson setup build "${OPTS[@]}"; fi
meson compile -C build
echo "Built. Now: sudo ./install.sh"
