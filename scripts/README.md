# Scripts

This directory is reserved for future helper scripts. Scripts in this repository should be source-only and must not include firmware, vendor binaries, patched binaries, or device dumps.

Expected script responsibilities:

- build the RTP timestamp fix proxy locally
- patch `system.img` offline using `debugfs` from WSL
- insert the proxy as `/lib/libbluetoothdrv.so`
- insert the original official library as `/lib/libbluetoothdrv_real.so`
- leave `/lib/libmtkbtextadpa2dp.so` untouched
- dump inserted files back out of the image
- verify SHA256 hashes
- run `e2fsck -f -n`

Scripts must never flash automatically. Flashing should remain a manual user action performed with the Innioasis Updater SP Flash Tool helper after reviewing the modified image and rollback plan.
