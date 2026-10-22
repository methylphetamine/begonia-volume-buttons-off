# Begonia Volume Buttons Off

A Magisk / KernelSU / APatch module that disables the physical **volume up**
and **volume down** buttons on the Xiaomi Redmi Note 8 Pro (`begonia`).

The power button, fingerprint sensor and every other key keep working. The
module only changes Android's key layout, so it takes effect after a reboot.

## Compatibility

- Xiaomi Redmi Note 8 Pro (`begonia`)
- Magisk 20.4+
- KernelSU (with or without a system-overlay metamodule; see below)
- APatch
- Android 10 and newer (the module uses the standard
  `/system/usr/keylayout/Generic.kl` path)

It does **not** disable the volume keys in recovery or fastboot; it only
affects the booted Android system.

## Install

1. Download the latest `begonia-volume-buttons-off-v*.zip` from the
   [Actions](../../actions) tab or a release.
2. Open Magisk, KernelSU or APatch.
3. Choose **Modules → Install from storage** and select the zip.
4. Reboot.

The module contains no persistent daemons. On Magisk, APatch and KernelSU with
a system-overlay metamodule, the manager mounts the replacement key layout
files during boot, before Android's input system starts. On KernelSU without
a metamodule, a small `post-fs-data.sh` fallback bind-mounts the patched files
instead.

## Verify

After rebooting, press volume up or volume down. The volume panel should not
appear. The power menu still works.

To see which key layout Android loaded:

```sh
adb shell dumpsys input | grep -i -A4 keylayout
```

## Uninstall

Disable or remove the module in Magisk / KernelSU / APatch, then reboot. The
original key layout is restored on the next boot.

## How it works

Android maps Linux key codes to Android key codes with text files in
`/system/usr/keylayout`, `/vendor/usr/keylayout` and `/odm/usr/keylayout`.
The module overlays the relevant files with copies of the AOSP `Generic.kl`
that omit these lines:

```text
key 114   VOLUME_DOWN
key 115   VOLUME_UP
key 257   VOLUME_UP
key 258   VOLUME_DOWN
```

The power key (`key 116 POWER`, plus the second power mapping at 152) and
`VOLUME_MUTE` (113) are left alone.

Files included:

```text
system/usr/keylayout/Generic.kl
system/usr/keylayout/mtk-kpd.kl
vendor/usr/keylayout/Generic.kl
vendor/usr/keylayout/mtk-kpd.kl
odm/usr/keylayout/Generic.kl
odm/usr/keylayout/mtk-kpd.kl
```

The `mtk-kpd.kl` copies cover devices whose keypad reports the MediaTek
`mtk-kpd` input name; the `Generic.kl` copies cover the fallback path used by
this device tree. The vendor and odm copies win over the system copies on
devices where those partitions take priority.

The module also ships `post-fs-data.sh`, a fallback for managers that do not
mount module `system/` directories, notably KernelSU without a metamodule.
It scans `/system`, `/vendor` and `/odm` key layouts at boot, copies any file
that still maps a volume key, removes the mapping, labels the copy as
`system_file` (the label Android's input service can read), and bind-mounts it
over the original. When the normal overlay is already active, the file has no
volume mapping and the script does nothing. KernelSU users who have
`meta-overlayfs` installed get the normal overlay path; users who do not still
get the bind-mount fallback.
`post-mount.sh` re-runs the same fallback after KernelSU's OverlayFS mount, so
device-specific key layouts that are not in the static overlay are covered
there too. Magisk and APatch ignore `post-mount.sh`.

## Troubleshooting

If the volume buttons still work:

1. Make sure the module is enabled and you rebooted.
2. Check the key layout path Android actually used:
   ```sh
   adb shell dumpsys input | grep -i -A4 keylayout
   ```
3. If it names a different file (for example an `odm` or device-specific
   layout), open an issue with that output.

## Build

The GitHub Actions workflow:

- validates that the zip has no `VOLUME_UP` / `VOLUME_DOWN` mappings and still
  has the power key;
- builds `begonia-volume-buttons-off-<version>.zip`;
- uploads the zip to **Gofile**;
- sends the zip to Telegram when `TELEGRAM_BOT_TOKEN` and
  `TELEGRAM_CHAT_ID` repository secrets are configured;
- uploads the zip as a workflow artifact;
- publishes a GitHub release for `v*` tags.

Workflow: [`.github/workflows/build.yml`](.github/workflows/build.yml)

## Credits

The key layout is derived from the Android Open Source Project's
`Generic.kl` (Apache License 2.0), as used by the begonia device tree.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
