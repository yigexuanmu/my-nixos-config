# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/packages.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/pkgs/tools/networking/clash-party.nix（pkgs.clash-party 的来源）
#     - configuration/modules/security/wrappers.nix
#     - configuration/system/networking.nix（clash-verge 相关）
# ────────────────────────────────────────────────────────────

{ pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.clash-party ];
}
