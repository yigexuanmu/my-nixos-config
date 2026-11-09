#!/usr/bin/env bash

find_sound() {
    local rel="sounds/freedesktop/stereo/$1" d
    for d in ${XDG_DATA_DIRS//:/ } "$HOME/.nix-profile/share" /run/current-system/sw/share /usr/share; do
        if [ -n "$d" ] && [ -f "$d/$rel" ]; then
            printf '%s' "$d/$rel"
            return 0
        fi
    done
    return 1
}

SOUND_FILE="$(find_sound camera-shutter.oga || true)"

COORDS=$(slurp)
if [ -z "$COORDS" ]; then
    exit 0
fi
if [ -n "$SOUND_FILE" ]; then
    (command -v pw-play >/dev/null && pw-play "$SOUND_FILE" || paplay "$SOUND_FILE") > /dev/null 2>&1 &
fi
grim -g "$COORDS" - | wl-copy && notify-send "Screenshot" "copy to clipboard"
