#!/usr/bin/env bash
set -euo pipefail

MIN_GAP_MS="${WAYBAR_RELOAD_GAP_MS:-1200}"
STAMP="${XDG_RUNTIME_DIR:-/tmp}/waybar-reload.stamp"
LOCK="${STAMP}.lock"

now_ms() { date +%s%3N; }

exec 9>"$LOCK"
flock 9

if [[ -f "$STAMP" ]]; then
    last="$(cat "$STAMP" 2>/dev/null || echo 0)"
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
    delta=$(( $(now_ms) - last ))
    if (( delta < MIN_GAP_MS )); then
        sleep "$(awk -v ms=$(( MIN_GAP_MS - delta )) 'BEGIN{printf "%.3f", ms/1000}')"
    fi
fi

now_ms > "$STAMP"
pkill -SIGUSR2 waybar 2>/dev/null || true
