# Release Policy

Innioasis has replied that community ROM distribution is allowed, including ROMs based on their firmware, as long as it does not break devices. They also forwarded the AirPods 2 fix feedback to their R&D team and may include a fix in an official firmware update if possible.

Ready-made community ROM releases may be provided for users who do not want to build the patch locally.

## Requirements For Community ROM Releases

- Clearly mark every ready-made ROM as an unofficial community build.
- Do not call community ROMs official firmware.
- Include warnings that flashing is at the user's own risk.
- Include battery, USB disconnect, and device model warnings.
- Include SHA256 checksums for release assets.
- Include rollback notes that point users back to original Innioasis Y1 firmware 3.0.7.
- Keep source code and the patch-kit workflow available for users who prefer to build locally.

## Repository Rules

The git repository should stay source-only. Do not commit firmware images, ROM zips, vendor libraries, patched binaries, dumps, logs, or Ghidra projects.

Release assets may be attached to GitHub Releases when they follow the community ROM requirements above.

Do not commit:

- `system.img`
- `boot.img`
- ROM zip files
- `*.so`
- `*.bin`
- `*.apk`
- device dumps
- Bluetooth logs
- Ghidra projects

## Recommended Release Assets

For ready-made community ROM releases, include:

- the unofficial community ROM zip
- `SHA256SUMS.txt`
- release notes with installation and rollback steps

For source-only releases, patch-kit assets may contain:

- documentation
- scripts
- checksum examples
- no firmware
- no vendor libraries
- no patched binaries
