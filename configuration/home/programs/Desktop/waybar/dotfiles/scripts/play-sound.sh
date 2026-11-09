#!/usr/bin/env bash
set -euo pipefail

name="${1:-message.oga}"

for d in ${XDG_DATA_DIRS//:/ } "$HOME/.nix-profile/share" /run/current-system/sw/share /usr/share; do
    [ -n "$d" ] || continue
    f="$d/sounds/freedesktop/stereo/$name"
    if [ -f "$f" ]; then
        if command -v pw-play >/dev/null 2>&1; then
            exec pw-play "$f"
        elif command -v paplay >/dev/null 2>&1; then
            exec paplay "$f"
        fi
        exit 0
    fi
done

exit 0
