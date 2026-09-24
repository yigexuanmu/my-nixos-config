#!/usr/bin/env bash
# One-click reinstall script (UEFI + disko LVM/btrfs + swapfile)
# Flow: disko partition -> verify mounts -> mkswapfile -> copy config -> nixos-install
# Usage on LiveCD:
#   git clone https://github.com/yigexuanmu/my-nixos-config.git
#   cd my-nixos-config
#   sudo ./reinstall.sh [--yes] [extra nixos-install args...]
#   --yes  skip the destructive confirmation (double-checks target disk by default)
set -euo pipefail

# ---------------- Config (edit as needed) ----------------
DISK_BY_ID="nvme-HYV512X3_XT__2024092900130"      # disk.main.device in disko.nix
VG="vg-mioha"                                      # lvm_vg name in disko.nix
FS_LABEL="pc-mioha"                                # btrfs filesystem label
FLAKE_ATTR="mioha-nix"                             # nixosConfigurations.<attr> in flake.nix
SWAP_SIZE="16G"
TARGET="/mnt/etc/nixos"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISKO_NIX="$SRC_DIR/configuration/device/disko.nix"

# Expected mount points (under /mnt), must match disko.nix
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
# Remaining args are passed through to nixos-install (e.g. --no-root-passwd --option ...)
# shellcheck disable=SC2124
EXTRA_ARGS="$@"

log() { echo "==> $*"; }
die() { echo "!! $*" >&2; exit 1; }

# ---------------- 0. Preflight checks ----------------
[ "$EUID" -eq 0 ] || die "Run as root: sudo $0"
[ -d /sys/firmware/efi ] || die "UEFI not detected (/sys/firmware/efi missing); this config only supports UEFI+GRUB"
[ -f "$DISKO_NIX" ] || die "disko config not found: $DISKO_NIX"
[ -e "/dev/disk/by-id/$DISK_BY_ID" ] || die "Target disk /dev/disk/by-id/$DISK_BY_ID not found, check hardware first"

if [ "$YES" -ne 1 ]; then
  echo "About to format this disk with disko (ALL DATA WILL BE DESTROYED):"
  echo "  /dev/disk/by-id/$DISK_BY_ID"
  lsblk "/dev/disk/by-id/$DISK_BY_ID" || true
  read -rp "Type YES to continue: " ans
  [ "$ans" = "YES" ] || die "Aborted"
fi

# ---------------- 1. disko partitioning ----------------
log "Partitioning with disko..."
nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- --mode disko "$DISKO_NIX"

# ---------------- 2. Verify disko finished ----------------
log "Checking LVM + mounts..."
vgs "$VG" >/dev/null || die "VG $VG missing, disko may have failed"
lvs "$VG/root" >/dev/null || die "LV $VG/root missing, disko may have failed"
blkid -L "$FS_LABEL" >/dev/null || die "btrfs label $FS_LABEL not found"

for mp in "${WANT_MOUNTS[@]}"; do
  findmnt "/mnt$mp" >/dev/null || die "/mnt$mp not mounted, disko may be incomplete"
done
log "LVM + mount checks passed"

# ---------------- 3. mkswapfile ----------------
if [ -f /mnt/swap/swapfile ]; then
  log "/mnt/swap/swapfile already exists, skipping creation"
else
  log "Creating swapfile ($SWAP_SIZE)..."
  btrfs filesystem mkswapfile --size "$SWAP_SIZE" /mnt/swap/swapfile
fi
swapon --show=NAME | grep -q "^/mnt/swap/swapfile$" || swapon /mnt/swap/swapfile
log "swap enabled: $(swapon --show=NAME,SIZE | grep swapfile || true)"

# ---------------- 4. Copy NixOS configuration ----------------
[ "$SRC_DIR" != "$TARGET" ] || die "Do not run the script from $TARGET, it would delete its own .git; clone elsewhere first"
log "Copying this repo to $TARGET ..."
mkdir -p "$TARGET"
cp -a "$SRC_DIR/." "$TARGET/"
rm -rf "$TARGET/.git"
# Install script is only used on LiveCD, never installed into the system,
# so /etc/nixos does not keep a disk-wiping button around
rm -f "$TARGET/reinstall.sh"
[ ! -e "$TARGET/.git" ] || die "Failed to remove $TARGET/.git, check manually"
[ ! -e "$TARGET/reinstall.sh" ] || die "Failed to exclude $TARGET/reinstall.sh, check manually"
[ -f "$TARGET/flake.nix" ] || die "$TARGET/flake.nix missing, config copy failed"
log "Config ready: $TARGET (.git removed)"

# ---------------- 5. nixos-install ----------------
log "nixos-install --flake $TARGET#$FLAKE_ATTR ..."
# shellcheck disable=SC2086
nixos-install --flake "$TARGET#$FLAKE_ATTR" \
  --option extra-substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org" \
  $EXTRA_ARGS

log "Install finished; remember to remove the install media before reboot"
