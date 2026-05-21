# Official 3.0.7 Fix Procedure

This is a high-level procedure for reproducing the confirmed Innioasis Y1 official firmware 3.0.7 AirPods RTP timestamp fix. It intentionally does not include firmware images, vendor libraries, or patched binaries.

## Confirmed Result

The final official 3.0.7 build uses an ADB-enabled `system.img` and the following runtime layout:

```text
/system/lib/libbluetoothdrv.so = RTP timestamp fix proxy
/system/lib/libbluetoothdrv_real.so = original official 3.0.7 libbluetoothdrv.so
/system/lib/libmtkbtextadpa2dp.so = untouched
```

Bluetooth works, AirPods audio works, and AirPods controls for play/pause, next track, and previous track work. No separate AVRCP patch is needed.

## High-Level Steps

1. Extract the official Innioasis Y1 firmware 3.0.7 package locally.
2. Copy `system.img` to a separate working file. Keep the original image unchanged.
3. Enable ADB by editing `build.prop` inside the copied `system.img`.
4. Build or obtain the RTP timestamp fix proxy locally.
5. Extract the original official 3.0.7 `/system/lib/libbluetoothdrv.so` from the firmware image.
6. Insert the proxy and real library into the copied `system.img`:

```text
/lib/libbluetoothdrv.so = RTP timestamp fix proxy
/lib/libbluetoothdrv_real.so = original official 3.0.7 libbluetoothdrv.so
```

Inside `system.img`, `/lib/...` maps to `/system/lib/...` at runtime.

7. Keep `/lib/libmtkbtextadpa2dp.so` untouched. Do not replace it for the final minimal fix.
8. Dump both inserted files back out of the image and compare SHA256 hashes with the source files:

```text
/lib/libbluetoothdrv.so
/lib/libbluetoothdrv_real.so
```

9. Run a read-only filesystem check on the modified image:

```text
e2fsck -f -n system.img
```

10. Flash the modified `system.img` using the Innioasis Updater SP Flash Tool helper.
11. Test Bluetooth on/off, AirPods connection, music playback, and AirPods media controls.

## Notes

For production builds, ADB may be visible while `adb remount` still fails. That is expected. The confirmed deployment path for official 3.0.7 is offline `system.img` modification rather than live replacement through `adb remount`.

Do not install the proxy by itself. If `/system/lib/libbluetoothdrv_real.so` is missing, Bluetooth may fail to initialize because the proxy has no original driver library to delegate to.
