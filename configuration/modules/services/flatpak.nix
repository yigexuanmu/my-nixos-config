# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/modules/programs/desktop.nix（xdg portal 配置已迁移至此）
#     - configuration/home/session.nix（flatpak 的 XDG_DATA_DIRS）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  services.flatpak.enable = true;

  # XDG portal 相关配置已迁移到 modules/programs/desktop.nix
}
