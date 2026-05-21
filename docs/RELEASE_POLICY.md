# Release Policy

GitHub Releases should not include full firmware images or vendor binaries unless explicit redistribution permission exists.

The recommended release type is documentation plus patch-kit scripts only. Users must provide their own official firmware and prepare patched images locally.

Do not upload:

- `system.img`
- `boot.img`
- `rom.zip`
- `*.so`
- `*.bin`
- device dumps
- Bluetooth logs
- Ghidra projects

## Recommended Release Asset

Example release asset name:

```text
innioasis-y1-airpods2-no-sound-fix-patch-kit-v1.0.0.zip
```

This should contain only:

- documentation
- scripts
- checksum examples
- no firmware
- no vendor libraries
- no patched binaries
