# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/system/user.nix（podman 用户组）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
