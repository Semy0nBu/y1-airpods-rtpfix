# Release Policy

GitHub Releases for this project should not contain full firmware images or vendor binaries unless the publisher has explicit redistribution rights.

The recommended release artifact is a patch kit only: documentation, source scripts, hashes, and reproducible instructions that require users to provide their own legally obtained firmware.

Users must provide their own official Innioasis Y1 firmware package and build or prepare patched images locally.

Do not upload:

- `system.img`
- `boot.img`
- `rom.zip`
- `*.so`
- device dumps
- logs with Bluetooth MAC addresses
- Ghidra projects or reverse engineering databases

Keep releases source-only unless redistribution rights are clear and documented.
