# Scripts

This directory is for helper scripts that are safe to publish. Scripts here should be source-only and should not include firmware, vendor binaries, patched binaries, or device dumps.

The current build script can compile the RTP timestamp fix proxy locally when you provide an Android NDK. Future scripts may help with image preparation, but they should stay careful and reversible.

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
