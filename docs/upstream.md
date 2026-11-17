# Upstream status

Everything here is a local fix; nothing below has been merged anywhere yet.

| Fix | Upstream | Status / next step |
|---|---|---|
| Keyboard, battery, fan, sensors (`MSHW0005`) | Linux kernel, platform-drivers-x86 (Surface: Maximilian Luz) | Patch ready: `keyboard-battery/0001-*.patch`, needs author name/email, then `git send-email` |
| Audio (phantom RT1320 amp) | Linux kernel sound / SOF (`thesofproject/linux`) | Patch from floopflop/SL_Intel_Linux. Better fix: a quirk for this model in the Intel SoundWire machine driver. Open an SOF issue with the kernel log |
| Touchpad | linux-surface/iptsd (via alex-lentz's fork) | Patches by floopflop on alex-lentz/iptsd; follow linux-surface/iptsd for native support |
| Front camera 12 MHz clock | Linux kernel media (`ov02c10`) | A patch exists on LKML (Jul 2026, "media: i2c: ov02c10: tolerate a sensor clock other than 19.2 MHz"). Send a **Tested-by** for this model |
| IR camera driver fixes | linux-surface/kernel PR #164 | Comment with `camera-ir/vd55g0-fixes-on-top-of-linux-surface-pr164.patch` (same sensor as Surface Pro 11) |
| IR emitter | linux-surface/kernel PR #164, linux-surface wiki | Share [ir-emitter.md](ir-emitter.md): strobe timing block, all GPIOs strobe, exposure ≤ 644 lines |
| `ipu-bridge` entry for `SMO55F0` | Linux kernel media | Only useful once a `vd55g0` driver is upstream |
| Camera support table | linux-surface wiki "Camera Support" | Add Surface Laptop 7 (Intel): OV02C10 ⚠️ (patch), VD55G0 ⚠️ (out of tree) |
| Omarchy | basecamp/omarchy | Ideas: notifications are drawn under the polkit dialog; a supported hook for non-fingerprint biometrics on the lock screen (this repo uses a `fprintd-list` shim) |
