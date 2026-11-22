# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/modules/programs/desktop.nix（programs.mango.enable）
#     - configuration/home/mango-session.nix（mango 会话 target）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  xdg.configFile = {
    "mango/config.conf".source = ./dotfiles/config.conf;
  };
}
