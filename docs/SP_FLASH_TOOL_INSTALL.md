# Installing The Locally Patched Image With SP Flash Tool

This guide assumes that you own the device and have legally obtained the official Innioasis Y1 firmware package. This repo does not include firmware images or vendor binaries.

The goal is to install a patched `system.img` that you prepared locally. The easiest path is to prepare that image first with `scripts/prepare_fixed_system_img.ps1`, then come back to this guide for the manual SP Flash Tool steps. Take your time with the verification steps. They are there to catch mistakes before anything is flashed.

## What This Guide Does

This guide covers installing a locally prepared `system.img` for official Innioasis Y1 firmware 3.0.7.

- You prepare a modified `system.img` locally.
- The modified image stays based on official firmware 3.0.7.
- Only the Bluetooth driver layout is changed.
- `boot.img` is not changed.
- `libmtkbtextadpa2dp.so` is not changed.
- The final image is flashed using the Innioasis Updater SP Flash Tool helper.

## Required Files

You need:

- Official Innioasis Y1 firmware 3.0.7
- Original `system.img`
- Original `boot.img`
- `MT6572_Android_scatter.txt`
- RTP timestamp fix proxy built locally
- Original official `libbluetoothdrv.so` extracted locally
- Windows PC
- Innioasis Updater
- WSL2/Ubuntu with `debugfs` and `e2fsck`

Keep firmware images, vendor libraries, patched binaries, dumps, and logs out of this repo.

## Expected Final Image Layout

Inside `system.img`, the expected final layout is:

```text
/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
/lib/libmtkbtextadpa2dp.so    = untouched original library
```

Inside `system.img`, `/lib/...` becomes `/system/lib/...` at runtime.

Do not install the proxy alone. It needs the original official Bluetooth driver at `/lib/libbluetoothdrv_real.so`.

## Installing The Ready-made Community ROM

A ready-made unofficial community ROM may be downloaded from GitHub Releases. This is the easiest install path if you do not want to build or patch `system.img` yourself.

1. Download this file from GitHub Releases:

```text
innioasis-y1-3.0.7-airpods2-fix-community-rom-v1.0.0.zip
```

2. Open this folder on your Windows PC:

```text
C:\Users\<USER>\AppData\Local\Innioasis Updater\Toolkit\SP Flash Tool
```

Replace `<USER>` with your Windows user name.

3. Drag the downloaded ROM zip onto:

```text
1. Drag the files from rom.zip here
```

4. Then run:

```text
2. Run Me + Connect Y1
```

5. Fully power off the Y1.
6. Connect the Y1 by USB only when the helper waits for the device.
7. Do not disconnect the USB cable while flashing.
8. Wait for flashing to finish.
9. Boot the player and test:

- Bluetooth
- AirPods 2 audio
- AirPods 2 media controls
- USB storage / disk access

Optional but recommended: verify the release zip SHA256 against `SHA256SUMS.txt` before flashing.

To roll back, flash the original Innioasis Y1 firmware 3.0.7 again with the Innioasis Updater / SP Flash Tool helper.

Do not use `Format All`.

Do not flash random partitions.

## Step 1 - Back Up The Original Updater Image

Use a PowerShell prompt. Replace `USER` with your Windows user name:

```powershell
$u = "C:\Users\USER\AppData\Local\Innioasis Updater"

Copy-Item "$u\system.img" "$u\system.img.official_backup_3_0_7" -Force
Get-FileHash "$u\system.img"
```

This backup gives you a simple rollback path. Keep it outside this repo and do not commit it.

## Step 2 - Verify The Patched system.img

Check the hash of your locally prepared patched image:

```powershell
Get-FileHash "D:\path\to\patched\system.img"
```

Run a read-only filesystem check from WSL:

```powershell
wsl sh -lc "cd /mnt/d/path/to/project && e2fsck -f -n patched/system.img"
```

`e2fsck` should finish without critical errors. The `-n` flag keeps the check read-only, so it should not modify the image.

## Step 3 - Verify The Two Bluetooth Libraries Inside The Image

Dump both Bluetooth driver files back out of the patched image and compare SHA256 hashes. This confirms that the proxy and original real library were placed where you expected.

Example from PowerShell:

```powershell
wsl sh -lc "cd /mnt/d/path/to/project && mkdir -p verify && debugfs -R 'dump /lib/libbluetoothdrv.so verify/libbluetoothdrv.so.from_img' patched/system.img && debugfs -R 'dump /lib/libbluetoothdrv_real.so verify/libbluetoothdrv_real.so.from_img' patched/system.img && sha256sum verify/libbluetoothdrv.so.from_img path/to/proxy/libbluetoothdrv.so verify/libbluetoothdrv_real.so.from_img path/to/original/libbluetoothdrv.so"
```

Expected result:

- the proxy hash must match `verify/libbluetoothdrv.so.from_img`
- the original official hash must match `verify/libbluetoothdrv_real.so.from_img`

Do not flash if either hash does not match. A mismatch usually means the wrong file was inserted or the wrong image was checked.

## Step 4 - Replace system.img In The Innioasis Updater Folder

Replace `USER` and the patched image path:

```powershell
$u = "C:\Users\USER\AppData\Local\Innioasis Updater"

Copy-Item "D:\path\to\patched\system.img" "$u\system.img" -Force

Get-FileHash "$u\system.img"
Get-FileHash "D:\path\to\patched\system.img"
```

The two hashes must match. This confirms the updater folder now contains the patched image you verified.

## Step 5 - Open SP Flash Tool Helper

Open this folder:

```text
C:\Users\USER\AppData\Local\Innioasis Updater\Toolkit\SP Flash Tool
```

Run:

```text
2. Run Me + Connect Y1
```

Then:

- Fully power off the Y1.
- Wait until the tool is ready for the device.
- Connect the Y1 by USB.
- Do not disconnect the cable during flashing.
- Wait for the flashing process to complete.

## Step 6 - First Boot Test

After flashing:

- Let the device fully boot.
- Turn Bluetooth on.
- Pair/connect AirPods 2.
- Start a local music track.
- Test sound.
- Test play/pause.
- Test next track.
- Test previous track.

These tests confirm both A2DP audio and AVRCP media controls.

## Rollback

To roll back, restore the backed up original `system.img` into the Innioasis Updater folder and re-run the SP Flash Tool helper.

This returns the system partition to the original official `system.img`.



