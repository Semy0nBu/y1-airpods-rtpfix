# Build From Source

This repository includes the C source code for the AirPods 2 RTP timestamp fix proxy. It does not include compiled `.so` binaries, firmware images, or vendor libraries.

## Required Tools

- Windows PowerShell
- Android NDK
- Git

The build script targets the 32-bit ARM Android userspace used by the Innioasis Y1 / MT6572 firmware.

## Set ANDROID_NDK_ROOT

Install the Android NDK locally, then set `ANDROID_NDK_ROOT` to the NDK directory.

Example PowerShell session:

```powershell
$env:ANDROID_NDK_ROOT = "C:\Android\android-ndk-r26d"
```

You can also pass the NDK path directly to the build script with `-AndroidNdkRoot`.

## Build The Minimal RTPFIX Proxy

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_minimal_airpods_rtpfix_proxy.ps1
```

Or pass the NDK path explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_minimal_airpods_rtpfix_proxy.ps1 -AndroidNdkRoot "C:\Android\android-ndk-r26d"
```

Expected output:

```text
build/libbluetoothdrv.so
```

The `build/` directory and generated `.so` files are ignored by git.

## What The Output Is

`build/libbluetoothdrv.so` is the RTP timestamp fix proxy. It must be inserted into `system.img` as:

```text
/lib/libbluetoothdrv.so
```

At runtime this becomes:

```text
/system/lib/libbluetoothdrv.so
```

The original official Innioasis Y1 firmware 3.0.7 `libbluetoothdrv.so` must be inserted separately as:

```text
/lib/libbluetoothdrv_real.so
```

At runtime this becomes:

```text
/system/lib/libbluetoothdrv_real.so
```

The proxy forwards real Bluetooth driver calls to `libbluetoothdrv_real.so` after normalizing outgoing A2DP/SBC RTP timestamps.

## Keep The Media Library Untouched

Do not replace or patch `libmtkbtextadpa2dp.so` for the final minimal fix. It must remain the untouched original library:

```text
/lib/libmtkbtextadpa2dp.so
/system/lib/libmtkbtextadpa2dp.so
```

## Safety

The build script only compiles source code into the ignored local `build/` folder. It does not use `adb`, flash anything, touch a connected device, or modify `system.img` automatically.
