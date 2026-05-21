# Innioasis Y1 AirPods RTP Timestamp Fix

This repository documents a confirmed software-side workaround for AirPods audio silence on the Innioasis Y1 / MT6572 Android-based music player.

The confirmed target is official Innioasis Y1 firmware 3.0.7. On this firmware, AirPods can connect over Bluetooth but may remain silent because the outgoing A2DP SBC media stream has broken RTP timestamp progression. The minimal fix is to normalize RTP timestamps in the Bluetooth driver write path while leaving the MediaTek A2DP media library untouched.

This repository is documentation and scripts only. It does not include firmware images, vendor libraries, patched binaries, device dumps, Bluetooth logs, or Ghidra projects.

## Confirmed Device And Firmware

- Device: Innioasis Y1 / MT6572 Android-based player
- Firmware: official 3.0.7
- ADB: enabled through `build.prop` inside `system.img`

## Final Working Layout

At runtime, the confirmed working system layout is:

```text
/system/lib/libbluetoothdrv.so = RTP timestamp fix proxy
/system/lib/libbluetoothdrv_real.so = original official 3.0.7 libbluetoothdrv.so
/system/lib/libmtkbtextadpa2dp.so = untouched
```

Important: the proxy must not be installed alone. It requires the original official `libbluetoothdrv.so` to be present as `/system/lib/libbluetoothdrv_real.so`, because the proxy forwards the real Bluetooth driver operations after applying the RTP timestamp fix.

## Confirmed Working

The final official 3.0.7 setup confirms:

- Bluetooth on/off
- AirPods connection
- music playback
- play/pause from AirPods
- next track from AirPods
- previous track from AirPods

AVRCP/media controls work in this final layout. No separate AVRCP patch is needed.

## Safety

Do not publish firmware or vendor binaries. Keep all firmware images, `.so` files, patched binaries, device dumps, logs with Bluetooth MAC addresses, and reverse engineering project files out of this repository.
## Release Policy

Releases should contain documentation, source scripts, and patch-kit materials only. Do not publish complete firmware images, `system.img`, `boot.img`, ROM zip files, `.so` vendor libraries, patched binaries, device dumps, or Bluetooth logs with MAC addresses.

Users must provide their own legally obtained firmware and build patched images locally.

