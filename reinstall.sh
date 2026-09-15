#!/usr/bin/env bash
# 一键重装脚本 (UEFI + disko LVM/btrfs + swapfile)
# 流程: disko 分区 -> 检查挂载 -> mkswapfile -> 复制配置 -> nixos-install
# LiveCD 下用法:
#   git clone https://github.com/yigexuanmu/my-nixos-config.git
#   cd my-nixos-config
#   sudo ./reinstall.sh [--yes] [nixos-install 额外参数...]
#   --yes  跳过 destructive 确认（默认会让你二次确认目标盘）
set -euo pipefail

# ---------------- 配置（按需改） ----------------
DISK_BY_ID="nvme-HYV512X3_XT__2024092900130"      # disko.nix 里 disk.main.device 对应的盘
VG="vg-mioha"                                      # disko.nix 里 lvm_vg 名
FS_LABEL="pc-mioha"                                # btrfs 卷标
FLAKE_ATTR="mioha-nix"                             # flake.nix 里 nixosConfigurations.<attr>
SWAP_SIZE="16G"
TARGET="/mnt/etc/nixos"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISKO_NIX="$SRC_DIR/configuration/modules/services/disko.nix"

# 期望挂载点（/mnt 下），必须和 disko.nix 一致
WANT_MOUNTS=(
  "/"
  "/efi"
  "/boot"
  "/etc"
  "/nix"
  "/nix/store"
  "/home"
  "/swap"
  "/var/lib"
  "/var/log"
  "/var/tmp"
)

YES=0
for arg in "${@:1:$#}"; do
  case "$arg" in
    --yes) YES=1; shift ;;
    *) break ;;
  esac
done
# 剩下的参数透传给 nixos-install（比如 --no-root-passwd --option ...）
# shellcheck disable=SC2124
EXTRA_ARGS="$@"

log() { echo "==> $*"; }
die() { echo "!! $*" >&2; exit 1; }

# ---------------- 0. 前置检查 ----------------
[ "$EUID" -eq 0 ] || die "请用 root 运行: sudo $0"
[ -d /sys/firmware/efi ] || die "没检测到 UEFI（/sys/firmware/efi 不存在），本配置只支持 UEFI+GRUB"
[ -f "$DISKO_NIX" ] || die "找不到 disko 配置: $DISKO_NIX"
[ -e "/dev/disk/by-id/$DISK_BY_ID" ] || die "找不到目标盘 /dev/disk/by-id/$DISK_BY_ID，先确认硬件"

if [ "$YES" -ne 1 ]; then
  echo "即将用 disko 格式化以下磁盘（数据全毁）:"
  echo "  /dev/disk/by-id/$DISK_BY_ID"
  lsblk "/dev/disk/by-id/$DISK_BY_ID" || true
  read -rp "输入 YES 继续: " ans
  [ "$ans" = "YES" ] || die "已取消"
fi

# ---------------- 1. disko 分区 ----------------
log "disko 分区中..."
nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- --mode disko "$DISKO_NIX"

# ---------------- 2. 检查 disko 是否完成 ----------------
log "检查 LVM + 挂载..."
vgs "$VG" >/dev/null || die "VG $VG 不存在，disko 可能没成功"
lvs "$VG/root" >/dev/null || die "LV $VG/root 不存在，disko 可能没成功"
blkid -L "$FS_LABEL" >/dev/null || die "找不到 btrfs 卷标 $FS_LABEL"

for mp in "${WANT_MOUNTS[@]}"; do
  findmnt "/mnt$mp" >/dev/null || die "/mnt$mp 没挂上，disko 可能没完成"
done
log "LVM + 挂载检查通过"

# ---------------- 3. mkswapfile ----------------
if [ -f /mnt/swap/swapfile ]; then
  log "/mnt/swap/swapfile 已存在，跳过创建"
else
  log "创建 swapfile ($SWAP_SIZE)..."
  btrfs filesystem mkswapfile --size "$SWAP_SIZE" /mnt/swap/swapfile
fi
swapon --show=NAME | grep -q "^/mnt/swap/swapfile$" || swapon /mnt/swap/swapfile
log "swap 已启用: $(swapon --show=NAME,SIZE | grep swapfile || true)"

# ---------------- 4. 复制 NixOS 配置 ----------------
log "复制本仓库到 $TARGET ..."
mkdir -p "$TARGET"
cp -a "$SRC_DIR/." "$TARGET/"
rm -rf "$TARGET/.git"
[ -f "$TARGET/flake.nix" ] || die "$TARGET/flake.nix 不存在，配置复制失败"
log "配置就绪: $TARGET"

# ---------------- 5. nixos-install ----------------
log "nixos-install --flake $TARGET#$FLAKE_ATTR ..."
# shellcheck disable=SC2086
nixos-install --flake "$TARGET#$FLAKE_ATTR" \
  --option extra-substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org" \
  $EXTRA_ARGS

log "安装完成，重启前记得拔掉安装介质"
