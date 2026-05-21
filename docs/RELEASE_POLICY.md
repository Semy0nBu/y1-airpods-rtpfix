# Release Policy

GitHub Releases for this project should stay source-only and patch-kit style unless there is clear permission to redistribute firmware or vendor binaries.

The recommended release type is documentation plus scripts. Users should provide their own official Innioasis Y1 firmware and prepare patched images locally.

Please do not upload:

- `system.img`
- `boot.img`
- `rom.zip`
- `*.so`
- `*.bin`
- device dumps
- Bluetooth logs
- Ghidra projects

This keeps the project useful without redistributing files that may be owned by the device vendor or may contain private device data.

## Recommended Release Asset

Example release asset name:

```text
innioasis-y1-airpods2-no-sound-fix-patch-kit-v1.0.0.zip
```

A release asset like this should contain only:

- documentation
- scripts
- checksum examples
- no firmware
- no vendor libraries
- no patched binaries
