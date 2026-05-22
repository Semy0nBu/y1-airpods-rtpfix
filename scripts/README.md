# Scripts

This directory is for helper scripts that are safe to publish. Scripts here should be source-only and should not include firmware, vendor binaries, patched binaries, or device dumps.

## Main Helper

`prepare_fixed_system_img.ps1` is the main user-facing helper. It prepares a patched copy of the user's own official `system.img` for the Innioasis Y1 AirPods 2 RTP timestamp fix.

It can build the RTP timestamp fix proxy from source with Android NDK, or it can use an already built local proxy with `-SkipBuild -ProxyPath`.

The script prepares files only. It does not flash automatically, does not call `adb`, and does not touch a connected device.

## Other Build Helper

`build_minimal_airpods_rtpfix_proxy.ps1` only builds the proxy into the ignored local `build/` folder. It does not patch images or flash anything.

Expected script responsibilities:

- build the RTP timestamp fix proxy locally
- patch `system.img` offline using `debugfs` from WSL
- insert the proxy as `/lib/libbluetoothdrv.so`
- insert the original official library as `/lib/libbluetoothdrv_real.so`
- leave `/lib/libmtkbtextadpa2dp.so` untouched
- dump inserted files back out of the image
- verify SHA256 hashes
- run `e2fsck -f -n`

Scripts should never flash automatically. Flashing should stay a manual user action with the Innioasis Updater SP Flash Tool helper, after the user has reviewed the modified image and has a rollback backup.
