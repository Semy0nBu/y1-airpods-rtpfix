# Installing The Locally Patched Image With SP Flash Tool

This guide assumes that you own the device and have legally obtained the official Innioasis Y1 firmware package. This repository does not include firmware images or vendor binaries.

## What This Guide Does

This guide covers installing a locally prepared `system.img` for official Innioasis Y1 firmware 3.0.7.

- You prepare a modified `system.img` locally.
- The modified image keeps official firmware 3.0.7.
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

Do not put firmware images, vendor libraries, patched binaries, dumps, or logs in this repository.

## Expected Final Image Layout

Inside `system.img`, the expected final layout is:

```text
/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
/lib/libmtkbtextadpa2dp.so    = untouched original library
```

Inside `system.img`, `/lib/...` becomes `/system/lib/...` at runtime.

Do not install the proxy alone. It requires the original official Bluetooth driver at `/lib/libbluetoothdrv_real.so`.

## Step 1 - Back Up The Original Updater Image

Use a PowerShell prompt. Replace `USER` with your Windows user name:

```powershell
$u = "C:\Users\USER\AppData\Local\Innioasis Updater"

Copy-Item "$u\system.img" "$u\system.img.official_backup_3_0_7" -Force
Get-FileHash "$u\system.img"
```

The backup is important for rollback. Keep it outside this repository and do not commit it.

## Step 2 - Verify The Patched system.img

Check the hash of your locally prepared patched image:

```powershell
Get-FileHash "D:\path\to\patched\system.img"
```

Run a read-only filesystem check from WSL:

```powershell
wsl sh -lc "cd /mnt/d/path/to/project && e2fsck -f -n patched/system.img"
```

`e2fsck` should finish without critical errors. The `-n` flag makes the check read-only.

## Step 3 - Verify The Two Bluetooth Libraries Inside The Image

Dump both files back out of the patched image and compare SHA256 hashes.

Example from PowerShell:

```powershell
wsl sh -lc "cd /mnt/d/path/to/project && mkdir -p verify && debugfs -R 'dump /lib/libbluetoothdrv.so verify/libbluetoothdrv.so.from_img' patched/system.img && debugfs -R 'dump /lib/libbluetoothdrv_real.so verify/libbluetoothdrv_real.so.from_img' patched/system.img && sha256sum verify/libbluetoothdrv.so.from_img path/to/proxy/libbluetoothdrv.so verify/libbluetoothdrv_real.so.from_img path/to/original/libbluetoothdrv.so"
```

Expected result:

- the proxy hash must match `verify/libbluetoothdrv.so.from_img`
- the original official hash must match `verify/libbluetoothdrv_real.so.from_img`

Do not flash if either hash does not match.

## Step 4 - Replace system.img In The Innioasis Updater Folder

Replace `USER` and the patched image path:

```powershell
$u = "C:\Users\USER\AppData\Local\Innioasis Updater"

Copy-Item "D:\path\to\patched\system.img" "$u\system.img" -Force

Get-FileHash "$u\system.img"
Get-FileHash "D:\path\to\patched\system.img"
```

The two hashes must match.

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

## Rollback

To roll back, restore the backed up original `system.img` into the Innioasis Updater folder and re-run the SP Flash Tool helper.

This returns the system partition to the original official `system.img`.
