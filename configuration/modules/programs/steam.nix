# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/programs/Games/default.nix（Steam 游戏包）
#     - configuration/modules/services/pipewire.nix（32 位音频）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  # 全局防火墙当前关闭，openFirewall 无效故不设
  programs.steam = {
    enable = true;
  };
}
