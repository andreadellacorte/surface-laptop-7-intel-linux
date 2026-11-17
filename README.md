# Linux on the Surface Laptop 7 (Intel)

Fixes to get a **Surface Laptop for Business 7th Edition with Intel** (Core Ultra 200V,
"Lunar Lake") fully working on Linux, including the **IR camera, its flood emitter and
Windows-Hello-style face unlock**.

Tested on Arch Linux / [Omarchy](https://omarchy.org) with kernel 7.2.15. The kernel
modules are DKMS packages, so they rebuild on kernel updates.

| Component | Without fixes | With this repo | Folder |
|---|---|---|---|
| Keyboard, battery, charger, fan, sensors | ❌ keyboard dead, no battery | ✅ | [`keyboard-battery/`](keyboard-battery) |
| Audio | ❌ no sound card | ✅ speakers, headphones, HDMI | [`audio/`](audio) |
| Touchpad | ⚠️ pointer only | ✅ two-finger scroll, palm rejection | [`touchpad/`](touchpad) |
| Front camera | ❌ driver refuses the 12 MHz clock | ✅ 1920×1080, ~18.8 fps (libcamera) | [`camera-front/`](camera-front) |
| IR camera | ❌ no driver | ✅ 640×600 @ 60 fps | [`camera-ir/`](camera-ir) |
| IR flood emitter | ❌ | ✅ reverse-engineered, see [docs/ir-emitter.md](docs/ir-emitter.md) | [`camera-ir/`](camera-ir) |
| Face unlock | ❌ | ✅ lock screen, polkit, sudo | [`face-unlock/`](face-unlock) |

> ⚠️ These are local kernel patches for one laptop model. Every part has an
> `uninstall.sh`. Keep an external keyboard around after big kernel updates: if a DKMS
> rebuild fails, the built-in keyboard is the first thing to stop working.

## Install

Install in this order. Each script says what it does and how to undo it.

```sh
# 1. Keyboard, battery, fan, sensors
cd keyboard-battery && sudo ./install.sh && cd ..

# 2. Audio
cd audio && sudo ./install.sh && cd ..

# 3. Touchpad (patched iptsd, built from source)
sudo pacman -S --needed meson ninja cmake cli11 eigen microsoft-gsl
cd touchpad && ./build.sh && sudo ./install.sh && cd ..

# 4. Front camera (+ virtual webcams for apps that don't speak libcamera)
cd camera-front && sudo ./install.sh && ./install-user.sh && cd ..

# 5. IR camera + emitter, then reboot
cd camera-ir && sudo ./install.sh && cd ..
sudo reboot

# 6. Face unlock (needs Howdy from the AUR)
yay -S howdy
cd face-unlock && sudo ./install.sh
# then enrol your face with the command it prints
```

## How the pieces fit

### Cameras

Both cameras sit behind Intel's IPU7 and are used through **libcamera** (`cam -l`). Apps
that only speak plain V4L2 (Qt Multimedia apps such as Monologue, OpenCV, Howdy) read
**virtual webcams** that a small GStreamer bridge feeds from libcamera on demand:

| Device | Name | Fed by |
|---|---|---|
| `/dev/video50` | Surface Camera | `surface-camera.service` (user), started by the Monologue launcher |
| `/dev/video51` | Surface IR Camera | `surface-ir-bridge` (root), started for each face check |

Browsers can use the front camera directly through PipeWire (`pipewire-libcamera`; in
Chromium enable `chrome://flags/#enable-webrtc-pipewire-camera`).

### Face unlock

A small root daemon (`surface-faceauthd`) owns the IR camera and runs
[Howdy](https://github.com/boltgolt/howdy)'s face check. PAM modules ask it over a local
socket (`/run/surface-faceauth.sock`, group `wheel`).

| Where | Behaviour |
|---|---|
| **Lock screen** | Automatic: after you lock, nothing runs until you press a key, touch the touchpad or screen, or open the lid. Then it checks your face and unlocks. Skipped with the lid closed. |
| **Password pop-ups (polkit)** and **sudo** | The face check starts when the prompt appears; a toast with what the IR camera saw tells you if you were recognised. **Press Enter on the empty field to approve.** Typing your password still works. |

Design choices:

- **sudo and polkit need a physical Enter.** The daemon only approves if a real key
  press arrived from an input device in the last 2 seconds, so a script running
  `echo | sudo -S …` cannot borrow your face while you sit in front of the laptop.
- **The lock screen** uses Omarchy's biometric (fingerprint) path. Omarchy only enables it
  when `fprintd-list` reports an enrolled finger, so a small shim in `/usr/local/bin`
  reports the Howdy face model instead. It would shadow a real `fprintd`; this laptop has
  no fingerprint reader.
- **Toasts** are a tiny Quickshell window built from Omarchy's own notification style
  modules (`Commons`, `Ui`), so they follow the theme. It is a separate window because
  Omarchy's own notifications are drawn under the polkit dialog. A big Omarchy update that
  reshapes those modules could break the toast (face unlock itself would keep working).
- Howdy 2.6.1 from the AUR expects `pam_python`, which isn't packaged; this repo uses
  plain `pam_exec` instead.

## Docs

- [docs/hardware.md](docs/hardware.md): device IDs, ACPI camera layout, GPIO map
- [docs/ir-emitter.md](docs/ir-emitter.md): how the IR camera and emitter were made to work
- [docs/upstream.md](docs/upstream.md): what should go upstream, and where

## What is not in this repo

No Microsoft driver files and no ACPI dumps (they include a Windows licence key and
machine identifiers). Only register values and decoded camera definitions taken from
them, which are the same on every unit of this model.

## Credits

- **Maximilian Luz** and the [linux-surface](https://github.com/linux-surface) project:
  Surface Aggregator Module driver this registry entry extends; the camera wiki.
- **floopflop** ([SL_Intel_Linux](https://github.com/floopflop/SL_Intel_Linux)):
  audio fix and the touchpad `iptsd` patches.
- **alex-lentz** ([iptsd fork](https://github.com/alex-lentz/iptsd)) and **nierdal**
  (LiftGraceMs): touchpad support.
- **André Gilerson** ([linux-surface/kernel PR #164](https://github.com/linux-surface/kernel/pull/164))
  and **STMicroelectronics**: the `vd55g0` driver this builds on.
- **Ryan Thomas Cragun**: the LKML patch letting `ov02c10` run on a non-19.2 MHz clock.
- [Howdy](https://github.com/boltgolt/howdy), [libcamera](https://libcamera.org),
  [Quickshell](https://quickshell.org), [Omarchy](https://omarchy.org).

Put together with [Claude Code](https://claude.com/claude-code).

## License

GPL-2.0 (see [LICENSE](LICENSE)). Third-party kernel sources keep their own
copyright headers.
