# Troubleshooting

## Bluetooth Does Not Turn On

Check that `/system/lib/libbluetoothdrv_real.so` exists and is the original official 3.0.7 `libbluetoothdrv.so`.

The RTP timestamp fix proxy is not a complete standalone Bluetooth driver. It must be installed as `/system/lib/libbluetoothdrv.so`, and the original driver must be available as `/system/lib/libbluetoothdrv_real.so`.

## AirPods Connect But There Is No Sound

Check that the RTP timestamp fix proxy is installed as `/system/lib/libbluetoothdrv.so`.

The confirmed AirPods audio fix normalizes outgoing A2DP SBC RTP timestamp progression in the Bluetooth driver write path.

## ADB Is Visible But Remount Fails

This is expected on production builds. ADB visibility does not imply that `/system` can be remounted read-write at runtime.

For production builds, modify `system.img` offline instead of trying to deploy through `adb remount`.

## Do Not Replace libmtkbtextadpa2dp.so

Do not replace `/system/lib/libmtkbtextadpa2dp.so` for the final minimal fix. The confirmed official 3.0.7 setup leaves this library untouched.

## Do Not Publish Sensitive Logs

Do not publish Bluetooth logs containing Bluetooth MAC addresses. Keep btsnoop captures, filtered logs, HCI logs, and packet captures out of the public repository unless they have been deliberately sanitized.
