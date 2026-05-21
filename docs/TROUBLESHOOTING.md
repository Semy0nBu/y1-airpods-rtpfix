# Troubleshooting

This page focuses on the common failure modes for the Innioasis Y1 official 3.0.7 AirPods 2 RTP timestamp fix.

## AirPods 2 Connect But Music Is Silent

This is the main confirmed symptom. AirPods 2 pair and connect normally, and playback appears to start on the Y1, but no audio is heard.

The expected fix is the RTP timestamp proxy installed as `/system/lib/libbluetoothdrv.so`, with the original official library available as `/system/lib/libbluetoothdrv_real.so`.

Also confirm that `/system/lib/libmtkbtextadpa2dp.so` is still the untouched original library.

## Bluetooth Does Not Turn On After Flashing

If Bluetooth no longer turns on after flashing, check the driver layout first.

Most likely causes:

- the proxy was installed without `libbluetoothdrv_real.so`
- the wrong original library was used as `libbluetoothdrv_real.so`
- file permissions are wrong
- `system.img` was not patched the way you expected

Expected permissions:

```text
-rw-r--r-- root root /system/lib/libbluetoothdrv.so
-rw-r--r-- root root /system/lib/libbluetoothdrv_real.so
```

The RTP timestamp fix proxy is not a full standalone Bluetooth driver. It must be installed as `/system/lib/libbluetoothdrv.so`, and the original official driver must be available as `/system/lib/libbluetoothdrv_real.so` so the proxy can forward real driver calls.

## Bluetooth Does Not Turn On

Check that `/system/lib/libbluetoothdrv_real.so` exists and is the original official 3.0.7 `libbluetoothdrv.so`.

If this file is missing, Bluetooth may fail during startup because the proxy has no real driver library to delegate to.

## AirPods Connect But There Is No Sound

Check that the RTP timestamp fix proxy is installed as `/system/lib/libbluetoothdrv.so`.

The confirmed AirPods audio fix normalizes outgoing A2DP/SBC RTP timestamp progression in the Bluetooth driver write path. It does not require replacing `libmtkbtextadpa2dp.so`.

## ADB Remount Fails

On official production builds, ADB can be visible but `adb root` and `adb remount` can still fail. This is expected and does not mean the whole fix is blocked.

For production builds, use offline `system.img` modification instead of trying to deploy through `adb remount`.

## ADB Is Visible But Remount Fails

ADB visibility only means the device exposes an ADB connection. It does not guarantee that `/system` can be remounted read-write at runtime.

For official production firmware, the reliable path is to modify `system.img` offline and flash the modified image with the updater helper.

## Do Not Replace libmtkbtextadpa2dp.so

Do not replace `/system/lib/libmtkbtextadpa2dp.so` for the final minimal fix. The confirmed official 3.0.7 setup leaves this library untouched.

If AirPods are silent, focus on the RTP timestamp proxy and the required `libbluetoothdrv_real.so` layout first.

## Do Not Publish Sensitive Logs

Do not publish Bluetooth logs containing Bluetooth MAC addresses. Keep btsnoop captures, filtered logs, HCI logs, and packet captures out of the public repo unless they have been deliberately sanitized.
