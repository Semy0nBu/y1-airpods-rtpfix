# Innioasis Y1 AirPods 2 No Sound Fix

This project documents a confirmed fix for the issue where AirPods 2 connect to the Innioasis Y1 Bluetooth music player, but music playback is silent. The confirmed fix works on official Innioasis Y1 firmware 3.0.7 by correcting A2DP/SBC RTP timestamp progression in the Bluetooth driver write path.

The Innioasis Y1 is an MT6572 Android-based music player. This repository is documentation and scripts only. It does not include firmware images, vendor libraries, patched binaries, device dumps, Bluetooth logs, or Ghidra projects.

## Problem

The main symptom is simple:

- AirPods 2 pair/connect normally.
- The Y1 shows Bluetooth playback.
- The music track appears to play.
- There is no sound in AirPods.
- Other headphones may work, so the problem is specific to AirPods compatibility with the Y1 A2DP/SBC stream.

Technically, the outgoing A2DP/SBC media stream is valid enough to start, but AirPods 2 remain silent because RTP timestamp progression is broken or incompatible.

## Confirmed Fix

The fix is not replacing the MediaTek A2DP media library. The final minimal fix leaves `libmtkbtextadpa2dp.so` untouched.

The working fix uses a proxy `libbluetoothdrv.so`. The proxy normalizes RTP timestamps in the Bluetooth driver write path and then forwards calls to the original Bluetooth driver saved as `libbluetoothdrv_real.so`.

Final confirmed layout:

```text
/system/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/system/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
/system/lib/libmtkbtextadpa2dp.so    = untouched original library
```

Important: the proxy must not be installed alone. It requires the original official `libbluetoothdrv.so` to be available as `/system/lib/libbluetoothdrv_real.so`. The earlier failure happened because the proxy was installed without `libbluetoothdrv_real.so`, which caused Bluetooth startup to fail.

## Confirmed Working Features

The final official 3.0.7 setup confirms:

- Bluetooth on/off
- AirPods 2 pairing
- AirPods 2 connection
- music playback
- play/pause from AirPods
- next track from AirPods
- previous track from AirPods

No separate AVRCP patch is needed.

## Documentation

- [Official 3.0.7 fix procedure](docs/OFFICIAL_3_0_7_FIX.md)
- [SP Flash Tool installation guide](docs/SP_FLASH_TOOL_INSTALL.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Release policy](docs/RELEASE_POLICY.md)

## Release Policy

This repository does not distribute complete firmware. This repository does not distribute vendor `.so` files.

Releases should contain documentation, scripts, and patch-kit style helpers only. Users must provide their own legally obtained official firmware package.

Do not upload `system.img`, `boot.img`, ROM zip files, vendor libraries, patched binaries, device dumps, or Bluetooth logs.

## Search Keywords

- Innioasis Y1 AirPods 2 no sound
- AirPods 2 connected but no audio Innioasis Y1
- Innioasis Y1 Bluetooth audio fix
- Y1 AirPods A2DP fix
- MT6572 Bluetooth RTP timestamp fix
- SBC RTP timestamp AirPods fix
- AirPods connected silent music player
- Innioasis Y1 official firmware 3.0.7 AirPods fix
