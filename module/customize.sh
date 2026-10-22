#!/system/bin/sh
# Magisk installer hook.  KernelSU/APatch installers may ignore this file.

ui_print() { echo "$1"; }

ui_print "- Begonia Volume Buttons Off"
ui_print "- Reboot to apply the new key layout"

# Magisk's default permissions make module-root files 0644.  The fallback
# bind-mount script must be executable on managers that run it directly.
if command -v set_perm >/dev/null 2>&1; then
    set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
    set_perm "$MODPATH/post-mount.sh" 0 0 0755
fi
