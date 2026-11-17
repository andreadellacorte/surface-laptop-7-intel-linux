# Hardware reference

Surface Laptop for Business 7th Edition with Intel (Core Ultra 200V, "Lunar Lake").
Everything here is model-level (ACPI / chip IDs), identical on every unit. Tested on
Arch / Omarchy with kernel 7.2.15.

| Part | Linux ID | Driver | Status |
|---|---|---|---|
| Keyboard, battery, charger, fan, sensors | SSAM `MSHW0005` | `surface_aggregator_registry` | needs the `sl7-sam` registry entry |
| Touchpad (haptic) | `quickspi-hid 045E:0C9F` | `iptsd` (userspace) | needs the patched `iptsd` |
| Audio | SoundWire, `sof_sdw` | `snd-soc-sdw-utils` | needs the `sl7-audio` patch (phantom RT1320 amp) |
| Image processor | PCI `8086:645d` (IPU7) | `intel_ipu7` (staging) | works |
| Front camera | ACPI `OVTI02C1` (OmniVision OV02C10) | `ov02c10` | needs the 12 MHz clock patch |
| IR camera | ACPI `SMO55F0` (ST VD55G0) | `vd55g0` (out of tree) | this repo |
| IR flood emitter | sensor GPIO1 (strobe) | `vd55g0` | this repo |

## Cameras in ACPI

```
\_SB.PC00.I2C5.CAMF   OVTI02C1   front RGB camera   2 CSI-2 lanes, IPU port 0
\_SB.PC00.I2C5.ICL0   INT3472    its power/clock controller (discrete GPIOs)
\_SB.PC00.I2C3.CAM3   SMO55F0    IR camera, I2C address 0x10, 1 CSI-2 lane, IPU port 1
\_SB.PC00.I2C3.ICL1   INT3472    its power/clock controller (discrete GPIOs)
```

Both sensors get a **fixed 12 MHz** clock (`SSDB` MCLK field `0x00B71B00`). The stock
`ov02c10` driver only accepts 19.2 MHz, which is why the front camera fails with
`external clock 12000000 is not supported`.

### IR controller `ICL1` GPIOs (from its `_DSM`)

| DSM value | Pin | Type | Mainline `int3472` name |
|---|---|---|---|
| `0x1000200B` | `0x20` | `0x0B` power enable | `avdd` |
| `0x10000810` | `0x08` | `0x10` DOVDD | `dovdd` |
| `0x10000900` | `0x09` | `0x00` reset | `reset` |
| `0x10000A0D` | `0x0A` | `0x0D` privacy LED | `SMO55F0_00::privacy_led` |

There is **no** emitter / strobe GPIO on the laptop side: the IR flood emitter is driven
by the sensor itself (see [ir-emitter.md](ir-emitter.md)). The "privacy LED" GPIO is not
the emitter.

### `SSDB` (sensor data buffer) fields of interest

| Field | Front (`CAMF`) | IR (`CAM3`) |
|---|---|---|
| link / lanes | port 0, 2 lanes | port 1, 1 lane |
| MCLK | 12 MHz | 12 MHz |
| flash | `0x02` | `0x02` |
| privacy LED | yes | yes |

## Windows driver package used for reference

Microsoft's driver MSI for this model (Download Center id 108014,
`SurfaceLaptop7withIntel_Win11_22631_26.081.15509.0.msi`) contains `vd55g0.sys`
(Intel, 70.26100.2.20795) plus tuning files for the three sensor-module variants
`MSHW0522`, `MSHW0552` and `MSHW0582`. Only register values were taken from it; no
Microsoft files are included in this repository. The Windows "FaceAuth" profile is
640×600 at 60 fps, NV12.
