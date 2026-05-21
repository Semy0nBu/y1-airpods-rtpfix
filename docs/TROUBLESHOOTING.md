# Troubleshooting

## AirPods 2 Connect But Music Is Silent

This is the confirmed main symptom. AirPods 2 pair/connect normally and playback appears to start on the Y1, but no audio is heard.

The expected fix is the RTP timestamp proxy installed as `/system/lib/libbluetoothdrv.so` with the original official library available as `/system/lib/libbluetoothdrv_real.so`.

Also confirm that `/system/lib/libmtkbtextadpa2dp.so` remains the untouched original library.

## Bluetooth Does Not Turn On After Flashing

Most likely causes:

- proxy was installed without `libbluetoothdrv_real.so`
- wrong original library was used
- file permissions are wrong
- `system.img` was not patched correctly

Expected permissions:

```text
-rw-r--r-- root root /system/lib/libbluetoothdrv.so
-rw-r--r-- root root /system/lib/libbluetoothdrv_real.so
```

The RTP timestamp fix proxy is not a complete standalone Bluetooth driver. It must be installed as `/system/lib/libbluetoothdrv.so`, and the original official driver must be available as `/system/lib/libbluetoothdrv_real.so`.

## Bluetooth Does Not Turn On

Check that `/system/lib/libbluetoothdrv_real.so` exists and is the original official 3.0.7 `libbluetoothdrv.so`.

If this file is missing, Bluetooth may fail during startup because the proxy has no real driver library to delegate to.

## AirPods Connect But There Is No Sound

Check that the RTP timestamp fix proxy is installed as `/system/lib/libbluetoothdrv.so`.

The confirmed AirPods audio fix normalizes outgoing A2DP/SBC RTP timestamp progression in the Bluetooth driver write path.

## ADB Remount Fails

On official production builds, ADB can be visible but `adb root` and `adb remount` can fail. This is expected.

Use offline `system.img` modification instead of trying to deploy through `adb remount`.

## ADB Is Visible But Remount Fails

ADB visibility does not imply that `/system` can be remounted read-write at runtime.

For production builds, modify `system.img` offline instead of trying to deploy through `adb remount`.

## Do Not Replace libmtkbtextadpa2dp.so

Do not replace `/system/lib/libmtkbtextadpa2dp.so` for the final minimal fix. The confirmed official 3.0.7 setup leaves this library untouched.

## Do Not Publish Sensitive Logs

Do not publish Bluetooth logs containing Bluetooth MAC addresses. Keep btsnoop captures, filtered logs, HCI logs, and packet captures out of the public repository unless they have been deliberately sanitized.
