# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：
#     - configuration/device/hardware/nvidia.nix
#     - configuration/device/hardware/hardware-config.nix
#     - configuration/device/hardware/bluetooth.nix
#   相关（语义关联）：configuration/device/disko.nix（同一台设备的磁盘布局）
# ────────────────────────────────────────────────────────────

{
  imports = [
    ../device/hardware/nvidia.nix
    ../device/hardware/hardware-config.nix
    ../device/hardware/bluetooth.nix
  ];
}
