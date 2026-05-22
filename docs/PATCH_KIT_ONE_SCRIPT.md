# One-Script Patch-Kit Workflow

This is the easiest safe workflow for preparing the Innioasis Y1 AirPods 2 no-sound fix.

The script does not include firmware. It does not flash the device. It builds the proxy locally, patches a copy of your own official `system.img`, verifies the result, and then stops. You still flash manually with the Innioasis Updater SP Flash Tool helper.

## What You Need First

- Innioasis Updater installed
- official Innioasis Y1 firmware 3.0.7 obtained legally
- Android NDK installed
- WSL2 Ubuntu with `debugfs`, `e2fsck`, and `sha256sum`
- this repository checked out locally

## What The Script Creates

The script creates:

```text
out/system_airpods2_fixed.img
```

Inside that image, the expected final layout is:

```text
/lib/libbluetoothdrv.so       = RTP timestamp fix proxy
/lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so
/lib/libmtkbtextadpa2dp.so    = untouched original library
```

At runtime, those paths become `/system/lib/...` on the device.

## Normal Use

From the repository root, run PowerShell like this:

```powershell
.\scripts\prepare_fixed_system_img.ps1 `
  -OriginalSystemImg "C:\Users\USER\AppData\Local\Innioasis Updater\system.img" `
  -AndroidNdkRoot "D:\Android\Sdk\ndk\23.2.8568313" `
  -OutputDir ".\out"
```

The script will:

- check that the input image exists
- check WSL and required Linux tools
- build the RTP timestamp fix proxy from source
- copy your original `system.img` to `out/system_airpods2_fixed.img`
- extract the original official `libbluetoothdrv.so`
- install the proxy as `/lib/libbluetoothdrv.so`
- install the original driver as `/lib/libbluetoothdrv_real.so`
- leave `/lib/libmtkbtextadpa2dp.so` untouched
- dump both inserted files back out
- compare SHA256 hashes
- run `e2fsck -f -n`

## Using An Already Built Local Proxy

If you already built the proxy locally, you can skip the build step:

```powershell
.\scripts\prepare_fixed_system_img.ps1 `
  -OriginalSystemImg "C:\path\to\system.img" `
  -SkipBuild `
  -ProxyPath "C:\path\to\libbluetoothdrv.so" `
  -OutputDir ".\out"
```

The provided proxy is copied into the local work folder and verified after insertion into the image.

## Flashing Is Still Manual

After the script finishes, manually copy the patched image to the Innioasis Updater folder after backing up the original:

```text
C:\Users\USER\AppData\Local\Innioasis Updater\system.img
```

Then open:

```text
C:\Users\USER\AppData\Local\Innioasis Updater\Toolkit\SP Flash Tool
```

Run:

```text
2. Run Me + Connect Y1
```

Fully power off the Y1, then connect it by USB when the tool waits for the device. Do not disconnect the cable during flashing.

## Safety Notes

The script prepares files only. It never calls `adb`, never flashes, and never touches a connected device.

The repo still does not distribute firmware, vendor libraries, compiled `.so` files, patched binaries, dumps, or private logs.
