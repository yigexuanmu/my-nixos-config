# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：flake.nix
#   下游（本文件引用）：
#     - configuration/mioha-main/packages.nix
#     - configuration/mioha-main/device.nix
#     - configuration/device/disko.nix
#     - configuration/system/boot.nix
#     - configuration/system/nix.nix
#     - configuration/system/overlays.nix
#     - configuration/system/networking.nix
#     - configuration/system/user.nix
#     - configuration/system/i18n.nix
#     - configuration/system/input-method.nix
#     - configuration/system/fonts.nix
#     - configuration/system/environment.nix
#     - configuration/system/tmpfiles.nix
#     - configuration/system/journald.nix
#   相关（语义关联）：
#     - configuration/mioha-main/modules.nix（与 system.nix 一起被 flake 引入）
#     - configuration/mioha-main/home.nix（同一主机）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  imports = [
    ./packages.nix
    ./device.nix
    ../device/disko.nix
    ../system/boot.nix
    ../system/nix.nix
    ../system/overlays.nix
    ../system/networking.nix
    ../system/user.nix
    ../system/i18n.nix
    ../system/input-method.nix
    ../system/fonts.nix
    ../system/environment.nix
    ../system/tmpfiles.nix
    ../system/journald.nix
  ];
}
