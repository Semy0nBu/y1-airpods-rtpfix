# Official 3.0.7 Fix Procedure

This guide shows the high-level process used for the confirmed Innioasis Y1 official firmware 3.0.7 AirPods 2 RTP timestamp fix. It does not include firmware images, vendor libraries, or patched binaries.

## Symptom

AirPods 2 pair and connect to the Y1, and the music player appears to play a track, but no sound comes through the AirPods. Other Bluetooth headphones may work on the same device.

The working diagnosis is that the outgoing A2DP/SBC media stream starts, but its RTP timestamp progression is broken or incompatible with AirPods 2.

## Confirmed Result

The final official 3.0.7 build uses an ADB-enabled `system.img` and this runtime layout:

```text
/system/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/system/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
/system/lib/libmtkbtextadpa2dp.so    = untouched original library
```

With that layout, Bluetooth works, AirPods 2 audio works, and AirPods controls for play/pause, next track, and previous track work. No separate AVRCP patch was needed.

## Important Proxy Requirement

Do not install the proxy by itself. The proxy forwards real driver operations to the original official Bluetooth driver library, which must be available as:

```text
/system/lib/libbluetoothdrv_real.so
```

If `libbluetoothdrv_real.so` is missing, Bluetooth may fail to start because the proxy has no real driver library to delegate to. The earlier failed layout installed the proxy without this required real library.

## High-Level Steps

1. Extract the official Innioasis Y1 firmware 3.0.7 package locally.
2. Copy `system.img` to a separate working file so the original image stays unchanged.
3. Enable ADB by editing `build.prop` inside the copied `system.img`.
4. Build or obtain the RTP timestamp fix proxy locally.
5. Extract the original official 3.0.7 `/system/lib/libbluetoothdrv.so` from the firmware image.
6. Insert the proxy and the original real library into the copied `system.img`:

```text
/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
```

Inside `system.img`, `/lib/...` maps to `/system/lib/...` at runtime.

7. Keep `/lib/libmtkbtextadpa2dp.so` untouched. Do not replace it for the final minimal fix.
8. Dump both inserted files back out of the image and compare SHA256 hashes with the source files:

```text
/lib/libbluetoothdrv.so
/lib/libbluetoothdrv_real.so
```

This check helps catch path mistakes before flashing.

9. Run a read-only filesystem check on the modified image:

```text
e2fsck -f -n system.img
```

10. Flash the modified `system.img` using the Innioasis Updater SP Flash Tool helper.
11. Test Bluetooth on/off, AirPods 2 connection, music playback, and AirPods media controls.

## Notes

On production firmware, ADB can be visible while `adb root` and `adb remount` still fail. That is expected. For production builds, the reliable path is offline `system.img` modification rather than live replacement through `adb remount`.

The final minimal fix leaves `libmtkbtextadpa2dp.so` untouched. The compatibility fix is in the Bluetooth driver write path, where the proxy normalizes outgoing A2DP/SBC RTP timestamps.
