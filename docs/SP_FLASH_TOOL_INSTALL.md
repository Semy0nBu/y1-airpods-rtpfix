# SP Flash Tool Installation

This guide explains how to install a locally patched `system.img` using the Innioasis Updater SP Flash Tool helper.

This guide assumes you legally obtained official Innioasis Y1 firmware 3.0.7. This repository does not distribute firmware, vendor libraries, patched binaries, or complete images. You must build or prepare the patched `system.img` locally.

## Expected Patched Image Layout

Inside `system.img`, the final expected layout is:

```text
/lib/libbluetoothdrv.so = RTP timestamp fix proxy
/lib/libbluetoothdrv_real.so = original official 3.0.7 libbluetoothdrv.so
/lib/libmtkbtextadpa2dp.so = untouched
```

Inside the Android runtime, these paths map to `/system/lib/...`.

Do not install the proxy alone. The proxy requires the original official Bluetooth driver library at `/lib/libbluetoothdrv_real.so`.

## Verify Before Flashing

Before replacing any updater files, verify the patched image contents locally.

Recommended checks:

1. Dump `/lib/libbluetoothdrv.so` back out of the patched image and compare its SHA256 hash with your locally built RTP timestamp fix proxy.
2. Dump `/lib/libbluetoothdrv_real.so` back out of the patched image and compare its SHA256 hash with the original official 3.0.7 `libbluetoothdrv.so`.
3. Confirm `/lib/libmtkbtextadpa2dp.so` was not modified.
4. Run a read-only filesystem check:

```text
e2fsck -f -n system.img
```

Do not flash if hashes do not match the expected local files.

## Back Up The Original Updater Image

The Innioasis Updater keeps its local image at a path like:

```text
C:\Users\<USER>\AppData\Local\Innioasis Updater\system.img
```

Before replacing it, make a backup copy of the original file. For example:

```text
C:\Users\<USER>\AppData\Local\Innioasis Updater\system.img.original_3_0_7_backup
```

Keep that backup outside this repository. Do not commit it.

## Replace system.img In The Updater Folder

After verifying your patched image, replace the updater copy:

```text
C:\Users\<USER>\AppData\Local\Innioasis Updater\system.img
```

Use your locally prepared patched `system.img` as the replacement.

## Open The SP Flash Tool Helper

Open the Innioasis Updater helper folder:

```text
C:\Users\<USER>\AppData\Local\Innioasis Updater\Toolkit\SP Flash Tool
```

Run:

```text
2. Run Me + Connect Y1
```

## Flashing Steps

1. Fully power off the Y1.
2. Start `2. Run Me + Connect Y1`.
3. When the tool waits for the device, connect the powered-off Y1 over USB.
4. Do not disconnect the USB cable during flashing.
5. Wait for the tool to finish before unplugging or powering on the device.

## Post-Flash Test

After the device boots, test:

- Bluetooth on/off
- AirPods connection
- music playback
- play/pause
- next track
- previous track
