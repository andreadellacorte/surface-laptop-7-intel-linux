# How the IR camera and emitter were made to work

The IR camera is an ST **VD55G0** (ACPI `SMO55F0`): 644×604 monochrome, global shutter,
with an IR flood emitter for Windows Hello. Nothing in mainline Linux drives either.

## 1. The sensor

Starting point: the out-of-tree `vd55g0` driver from
[linux-surface/kernel PR #164](https://github.com/linux-surface/kernel/pull/164)
(Surface Pro 11, port of ST's driver). It needed these fixes on this laptop
(`camera-ir/vd55g0-fixes-on-top-of-linux-surface-pr164.patch`):

| Problem | Symptom | Fix |
|---|---|---|
| Asked for supply `pwr2`, a name only the PR's patched `int3472` creates | silently gets a dummy regulator; sensor half-powered | use mainline's name `dovdd` |
| Reset GPIO only requested on the device-tree path | sensor held in reset, `sensor detect failed -121` | request `reset` (and optional `powerdown`) on every path |
| `poll_reg()` returned 0 when the I2C read failed | errors reported as success | propagate the read error |
| `ipu-bridge` doesn't know `SMO55F0` | sensor never linked to the IPU | add `IPU_SENSOR_CONFIG("SMO55F0", 1, 402000000)` (matches the driver's 402 MHz link) |

`ipu-bridge` must be the patched one **from boot**: unloading and reloading the camera
stack at runtime leaves stale software nodes and the sensors don't get connected.

With that the sensor streams 640×600 @ 60 fps through libcamera's simple pipeline,
but indoors the image is black: the emitter is off.

## 2. Finding the emitter

What **didn't** work:

- The `SMO55F0_00::privacy_led` GPIO (the only extra GPIO on the IR controller): no light.
- Each sensor GPIO in strobe mode (`GPIO_x_CTRL = 0x02`), alone or with the LED GPIO: no light.
- A phone camera (which sees IR) showed a **single flicker** at the moment a GPIO was
  switched to strobe mode, then nothing.

What did: reading Microsoft's Windows driver (`vd55g0.sys`).

1. Its register-sequence tables (16-byte entries `{size, addr, value, 0}`) set **all four
   sensor GPIOs to `0x02` (strobe)** and then write a block the Linux driver never
   touches:

   ```
   0x0473 = 0xfe   0x0472 = 0x5b   0x0471 = 0x00   0x0470 = 0x08
   0x0476 = 0x00   0x0477 = 0x00   0x0478 = 0x00   0x0479 = 0x00
   ```

   (strobe/LED timing; written in this order).
2. The same tables use **manual exposure: `EXP_MODE = 2`, coarse exposure 644 lines**
   (out of ~1942 lines per frame, about a third of the frame time).
3. The Linux driver defaults to the sensor's own auto-exposure, which in a dark room
   pushes exposure to the full frame (1796 of 1860 lines). The strobe follows the
   exposure, so the emitter would be on ~97% of the time, and the **emitter's
   eye-safety circuit cuts it**: that was the single flicker.

With the timing block, all GPIOs on strobe and exposure ≤ 644 lines, the emitter lights
every frame. It is wired to **GPIO1**.

## 3. What the driver does now

`camera-ir/dkms/vd55g0.c`, module parameter `ir_emitter` (default on):

- writes the strobe timing block and sets all four GPIOs to strobe at stream start,
- starts in manual exposure, 644 lines, analog gain `0x18`, digital gain 1×
  (libcamera's AGC drives exposure and analog gain but not digital gain, so a higher
  digital gain just blows the image out),
- **clamps exposure to 644 lines** and refuses the sensor's auto-exposure while the
  emitter is enabled (eye-safety limit),
- `ir_emitter=0` gives the old behaviour (no emitter, sensor auto-exposure).

Measured cost on battery: IR sensor + emitter + libcamera ≈ 0.05–0.3 W while streaming.

## 4. Debug controls (on the sensor's `v4l-subdev`)

| Control | Use |
|---|---|
| `debug_reg_addr` / `debug_reg_value` | read/write any sensor byte register **while streaming** (volatile read) |
| `ir_led_gpio_mask` | which GPIOs (bitmask 0–15) to put in strobe mode |
| `ir_gpio0_raw` | raw value for `GPIO_0_CTRL` (Windows uses `0x12` / `0x02` / `0x05` for its own on/off modes) |

Example, while something streams the IR camera:

```sh
SD=/dev/$(basename $(dirname $(grep -l vd55g0 /sys/class/video4linux/v4l-subdev*/name)))
v4l2-ctl -d $SD -c debug_reg_addr=0x0064 && v4l2-ctl -d $SD -C debug_reg_value   # applied exposure, low byte
```

## Open questions

- The exact meaning of `0x0470`–`0x0479` (strobe start/width?) and of `GPIO_x_CTRL`
  bit 4 (`0x12`), used by Windows' "torch" control, are unknown without the datasheet.
- Whether the other two module variants (`MSHW0522`, `MSHW0582`) behave the same.
