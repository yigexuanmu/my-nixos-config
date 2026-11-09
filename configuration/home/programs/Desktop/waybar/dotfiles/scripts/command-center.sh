#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="${FLAKE_DIR:-/etc/nixos}"

report_error() {
  local error_msg="$1"
  printf '错误：%s\n' "$error_msg" >&2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical -a "Command Center" "NixOS 指令异常" "$error_msg" || true
  fi
}

if ! command -v kitty >/dev/null 2>&1; then
  report_error "未找到 kitty 终端，请先安装。"
  exit 1
fi

OPTIONS_ARR=()
declare -A ACTIONS=()

add() {
  OPTIONS_ARR+=("$1")
  ACTIONS["$1"]="$2"
}

add "更新 flake 锁 (nix flake update)" "nix flake update --flake $FLAKE_DIR"
add "更新并切换系统 (nixos-rebuild switch --upgrade)" "sudo nixos-rebuild switch --flake $FLAKE_DIR --upgrade"
add "仅构建不激活 (nixos-rebuild build)" "sudo nixos-rebuild build --flake $FLAKE_DIR"
add "列出系统代际 (list-generations)" "nixos-rebuild list-generations"

add "系统清理 (nix-collect-garbage -d)" "sudo nix-collect-garbage -d"
add "深度清理 (保留 30 天 + store gc + optimise)" \
  "sudo nix-collect-garbage -d --delete-older-than 30d && sudo nix store gc && sudo nix store optimise"

if [[ "$(stat -f -c %T / 2>/dev/null || true)" == "btrfs" ]] && command -v snapper >/dev/null 2>&1; then
  add "快速存档 (snapper create)" "sudo snapper create -d quicksave --print-number"
  add "列出快照 (snapper list)" "sudo snapper list"
fi

if systemctl is-active --quiet NetworkManager; then
  if systemctl is-active --quiet iwd && command -v impala >/dev/null 2>&1; then
    NET_TOOL="impala"
  else
    NET_TOOL="nmtui"
  fi
  add "联网工具 ($NET_TOOL)" "$NET_TOOL"
fi

if [[ -d /sys/class/bluetooth ]] && [[ -n "$(ls -A /sys/class/bluetooth 2>/dev/null || true)" ]]; then
  BT_TOOL="bluetoothctl"
  for t in bluetui bluetuith blueman-manager; do
    if command -v "$t" >/dev/null 2>&1; then
      BT_TOOL="$t"
      break
    fi
  done
  add "蓝牙工具 ($BT_TOOL)" "$BT_TOOL"
fi

if [[ ${#OPTIONS_ARR[@]} -eq 0 ]]; then
  report_error "未探测到任何可用的维护指令。"
  exit 1
fi

SELECTED="$(printf '%s\n' "${OPTIONS_ARR[@]}" | fuzzel --dmenu \
  -p "NixOS 指令 > " \
  --placeholder "命令可手动运行" \
  --placeholder-color 80808099 || true)"

[[ -z "$SELECTED" ]] && exit 0

CMD="${ACTIONS[$SELECTED]:-}"
if [[ -z "$CMD" ]]; then
  report_error "未知的选项: $SELECTED"
  exit 1
fi

kitty --single-instance --class command-center --title "$SELECTED" \
  bash -c "$CMD; echo; echo '按任意键退出...'; read -n 1 -s -r"
