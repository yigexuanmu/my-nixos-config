# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：configuration/modules/packages/clash-party.nix
#   相关（语义关联）：configuration/modules/security/wrappers.nix（同一个 clash-party 包）
# ────────────────────────────────────────────────────────────

{
  imports = [
    ../modules/packages/clash-party.nix
  ];
}
