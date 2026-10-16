#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/shorin-check-nix-updates"
CACHE_FILE="$CACHE_DIR/pending.txt"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-nix-updates.lock"
CHECK_INTERVAL="${CHECK_INTERVAL:-3600}"
MAX_LINES="${MAX_LINES:-50}"
FLAKE_DIR="${FLAKE_DIR:-}"
SYSTEM_PROFILE="${SYSTEM_PROFILE:-/nix/var/nix/profiles/system}"

MODE="loop"
[[ "${1:-}" == "--once" ]] && MODE="once"
FORCE_UPDATE=0

mkdir -p "$CACHE_DIR"
trap 'FORCE_UPDATE=1' SIGUSR1

json_str() { jq -Rn --arg s "$1" '$s'; }

format_age() {
  local s="$1"
  (( s < 0 )) && s=0
  if   (( s < 60 ));       then printf '刚刚'
  elif (( s < 3600 ));     then printf '%d 分钟前' $(( s / 60 ))
  elif (( s < 86400 ));    then printf '%d 小时前' $(( s / 3600 ))
  elif (( s < 2592000 ));  then printf '%d 天前'   $(( s / 86400 ))
  elif (( s < 31536000 )); then printf '%d 个月前' $(( s / 2592000 ))
  else                          printf '%d 年前'   $(( s / 31536000 ))
  fi
}

last_activation_info() {
  local t
  t="$(stat -c %Y "$SYSTEM_PROFILE" 2>/dev/null || true)"
  if [[ -z "$t" ]]; then
    printf '上次系统激活：未知'
    return 0
  fi
  printf '上次系统激活：%s' "$(format_age $(( $(date +%s) - t )))"
}

resolve_flake() {
  local d
  if [[ -n "$FLAKE_DIR" ]]; then
    printf '%s' "$FLAKE_DIR"
    return 0
  fi
  for d in /etc/nixos "$HOME/nixos" "$HOME/.config/nixos" "$HOME/nix-config"; do
    if [[ -f "$d/flake.nix" ]]; then
      printf '%s' "$d"
      return 0
    fi
  done
  return 1
}

locked_inputs() {
  nix flake metadata --json "$1" 2>/dev/null | jq -r '
    .locks.nodes as $n
    | ($n.root.inputs // {}) | to_entries[]
    | .key as $name
    | ($n[.value] // {}) as $v
    | select($v.locked.type == "github")
    | [$name, "\($v.locked.owner)/\($v.locked.repo)", ($v.locked.ref // "HEAD"), $v.locked.rev]
    | @tsv' 2>/dev/null || true
}

remote_rev() {
  nix flake metadata --refresh --json "github:$1/$2" 2>/dev/null \
    | jq -r '.revision // ""' 2>/dev/null || true
}

collect_updates() {
  local flake="$1" name repo ref locked remote
  while IFS=$'\t' read -r name repo ref locked; do
    [[ -z "${name:-}" ]] && continue
    remote="$(remote_rev "$repo" "$ref")"
    [[ -z "$remote" || "$remote" == "$locked" ]] && continue
    printf '%s\n' "${name} (${repo}): ${locked:0:7} → ${remote:0:7}"
  done < <(locked_inputs "$flake")
}

emit_json() {
  local updates="$1" count=0 info tooltip=""
  info="$(last_activation_info)"
  updates="$(printf '%s' "$updates" | grep -v '^[[:space:]]*$' || true)"
  if [[ -n "$updates" ]]; then
    count="$(printf '%s\n' "$updates" | wc -l)"
  fi
  if (( count > MAX_LINES )); then
    tooltip="$(printf '%s\n' "$updates" | head -n "$MAX_LINES")"
    tooltip+=$'\n'
    tooltip+="…… 另有 $(( count - MAX_LINES )) 个"
  else
    tooltip="$updates"
  fi
  if [[ -n "$tooltip" ]]; then
    tooltip+=$'\n'
    tooltip+='----------------'
    tooltip+=$'\n'
  fi
  tooltip+="$info"
  if (( count == 0 )); then
    printf '{"text": "", "alt": "updated", "tooltip": %s}\n' "$(json_str "$tooltip")"
  else
    printf '{"text": "%s", "alt": "has-updates", "tooltip": %s}\n' "$count" "$(json_str "$tooltip")"
  fi
}

run_check() {
  local flake updates
  if (( FORCE_UPDATE == 0 )) && [[ -f "$CACHE_FILE" ]]; then
    if (( $(date +%s) - $(stat -c %Y "$CACHE_FILE") < CHECK_INTERVAL - 10 )); then
      emit_json "$(cat "$CACHE_FILE")"
      return 0
    fi
  fi
  FORCE_UPDATE=0
  if ! flake="$(resolve_flake)"; then
    emit_json ""
    return 0
  fi
  trap '' SIGUSR1
  (
    if flock -x -n 9 || flock -x -w 300 9; then
      updates="$(collect_updates "$flake" || true)"
      printf '%s\n' "$updates" >"$CACHE_FILE.tmp"
      mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    fi
  ) 9>"$LOCK_FILE" || true
  trap 'FORCE_UPDATE=1' SIGUSR1
  if [[ -f "$CACHE_FILE" ]]; then
    emit_json "$(cat "$CACHE_FILE")"
  else
    emit_json ""
  fi
}

if [[ "$MODE" == "once" ]]; then
  flake="$(resolve_flake || true)"
  if [[ -z "$flake" ]]; then
    printf '未找到 flake：设置 FLAKE_DIR，或把配置放在 /etc/nixos\n'
    exit 1
  fi
  printf 'flake: %s\n' "$flake"
  out="$(collect_updates "$flake" || true)"
  if [[ -z "$out" ]]; then
    printf '所有 github 类输入均为最新\n'
  else
    printf '%s\n' "$out"
  fi
  printf -- '----------------\n'
  last_activation_info
  printf '\n'
  exit 0
fi

while true; do
  run_check
  sleep "$CHECK_INTERVAL" &
  wait $! || true
done
