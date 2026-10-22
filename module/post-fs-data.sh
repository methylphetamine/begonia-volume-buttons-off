#!/system/bin/sh
# Fallback for managers that do not mount the module's system/ directory
# (notably KernelSU without a metamodule such as meta-overlayfs).
#
# Some managers apply the module's static overlay before this script, in which
# case the target file has no VOLUME_UP/VOLUME_DOWN mapping and is left alone.
# Others apply the overlay after the script; the overlay then stacks the same
# patched file on top.  On managers without a system overlay this script is the
# only mechanism.
#
# The script copies each key layout that still contains a volume mapping,
# removes the mapping, labels the copy as system_file, and bind-mounts it over
# the original.  This runs in the post-fs-data stage, before zygote and
# system_server start.

MODDIR=${0%/*}
LOG="$MODDIR/post-fs-data.log"
exec >>"$LOG" 2>&1 || exit 0

echo "=== $(date) ==="
WORK="$MODDIR/.work"
mkdir -p "$WORK" || exit 0
changed=0

patch_file() {
    f="$1"
    [ -f "$f" ] || return 0

    # Already patched by the module overlay?
    if ! grep -qE '^[[:space:]]*key[[:space:]]+[0-9]+[[:space:]]+VOLUME_(UP|DOWN)([[:space:]]|$)' "$f"; then
        return 0
    fi

    out="$WORK/$(printf '%s' "$f" | tr '/' '_')"
    awk '$1 != "key" || $3 !~ /^VOLUME_(UP|DOWN)$/' "$f" > "$out" || return 0
    if cmp -s "$f" "$out"; then
        rm -f "$out"
        return 0
    fi

    # system_server needs read access to the mounted file.  Label the copy as
    # system_file; SELinux checks the inode label, not the target path.
    ctx="u:object_r:system_file:s0"
    if command -v chcon >/dev/null 2>&1; then
        chcon "$ctx" "$out" 2>/dev/null || echo "chcon failed: $f"
    fi

    if mount --bind "$out" "$f"; then
        echo "patched: $f"
        changed=$((changed + 1))
    else
        echo "mount failed: $f"
        rm -f "$out"
    fi
}

for dir in /system/usr/keylayout /vendor/usr/keylayout /odm/usr/keylayout; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.kl; do
        [ -f "$f" ] || continue
        patch_file "$f"
    done
done

echo "done; bind mounts: $changed"
