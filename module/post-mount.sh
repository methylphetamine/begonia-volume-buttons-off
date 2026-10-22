#!/system/bin/sh
# KernelSU runs this after its OverlayFS metamodule has mounted system/.
# Re-run the fallback so key layouts that were not covered by the module's
# static files (for example a device-specific .kl) are patched as well.
# Magisk and APatch ignore this file.

MODDIR=${0%/*}
exec "$MODDIR/post-fs-data.sh"
