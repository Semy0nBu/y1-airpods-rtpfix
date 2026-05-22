# Innioasis Y1 AirPods 2 No Sound Fix

This repo explains a confirmed fix for a specific Innioasis Y1 Bluetooth problem: AirPods 2 connect normally, but music playback is silent. The confirmed fix works on official Innioasis Y1 firmware 3.0.7 by correcting A2DP/SBC RTP timestamp progression in the Bluetooth driver write path.

The Innioasis Y1 is an MT6572 Android-based music player. This repo is meant to share the source code, notes, and careful build/install guidance. It does not include firmware images, vendor libraries, patched binaries, device dumps, Bluetooth logs, or Ghidra projects.

## Problem

The visible symptom is easy to recognize:

- AirPods 2 pair and connect normally.
- The Y1 shows Bluetooth playback.
- The music track appears to be playing.
- No sound comes through the AirPods.
- Other Bluetooth headphones may still work, so this looks like an AirPods compatibility issue with the Y1 A2DP/SBC stream.

The technical issue is in the outgoing A2DP/SBC media stream. It starts well enough for playback to begin, but the RTP timestamp progression is broken or incompatible, and AirPods 2 stay silent.

## Confirmed Fix

The final fix does not replace the MediaTek A2DP media library. The confirmed minimal setup leaves `libmtkbtextadpa2dp.so` untouched.

The working fix uses a proxy `libbluetoothdrv.so`. The proxy sits in the Bluetooth driver write path, normalizes outgoing RTP timestamps, and then forwards the real Bluetooth driver calls to the original official driver saved as `libbluetoothdrv_real.so`.

Final confirmed layout:

```text
/system/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/system/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
/system/lib/libmtkbtextadpa2dp.so    = untouched original library
```

Please do not install the proxy by itself. It needs the original official `libbluetoothdrv.so` to be available as `/system/lib/libbluetoothdrv_real.so`. The earlier failed attempt missed this real library, and Bluetooth could fail to start because the proxy had nothing to forward calls to.

## Confirmed Working Features

On the final official 3.0.7 setup, these were confirmed:

- Bluetooth on/off
- AirPods 2 pairing
- AirPods 2 connection
- music playback
- play/pause from AirPods
- next track from AirPods
- previous track from AirPods

No separate AVRCP patch was needed.

## Ready-made community ROM

A ready-made unofficial community ROM is available in GitHub Releases.

It is based on Innioasis Y1 official firmware 3.0.7 and includes the AirPods 2 no-sound fix.

This is not an official Innioasis firmware release.

The release build keeps normal stock-like USB storage behavior and does not enable ADB.

For users who prefer not to build the patch locally, download the community ROM from the Releases page and follow the release installation notes.

Also keep the source/build instructions for users who prefer to build locally.

## Source Code

The fix source code is in `src/libbluetoothdrv_proxy/libbluetoothdrv_proxy.c`.

It builds a `libbluetoothdrv.so` proxy. The proxy normalizes outgoing A2DP/SBC RTP timestamps for AirPods 2 compatibility, then forwards real Bluetooth driver calls to `libbluetoothdrv_real.so`.

This repo does not include the compiled proxy binary. Build output is created locally under `build/`, which is ignored by git.


## Easiest Safe Install Path

The repo now includes source code and a helper script that prepares the patched `system.img` locally from your own official firmware image.

Start here: [One-script patch-kit workflow](docs/PATCH_KIT_ONE_SCRIPT.md).

The helper script builds the RTP timestamp fix proxy, patches a copy of your own `system.img`, verifies the inserted files, and stops. It does not include firmware, does not include vendor binaries, does not flash, and does not call `adb`. Flashing is still a manual step through the Innioasis Updater SP Flash Tool helper.

## Documentation
- [Official 3.0.7 fix procedure](docs/OFFICIAL_3_0_7_FIX.md)
- [Build from source](docs/BUILD_FROM_SOURCE.md)
- [SP Flash Tool installation guide](docs/SP_FLASH_TOOL_INSTALL.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Release policy](docs/RELEASE_POLICY.md)

## Release Policy

The git repo stays source-only: do not commit `system.img`, `boot.img`, ROM zip files, vendor libraries, patched binaries, device dumps, or Bluetooth logs.

GitHub Releases may provide ready-made unofficial community ROM assets when they are clearly labeled as community builds and include safety notes, checksums, and rollback instructions.

Source code and patch-kit workflows remain available for users who prefer to build locally from their own official firmware package.

## Search Keywords

- Innioasis Y1 AirPods 2 no sound
- AirPods 2 connected but no audio Innioasis Y1
- Innioasis Y1 Bluetooth audio fix
- Y1 AirPods A2DP fix
- MT6572 Bluetooth RTP timestamp fix
- SBC RTP timestamp AirPods fix
- AirPods connected silent music player
- Innioasis Y1 official firmware 3.0.7 AirPods fix



