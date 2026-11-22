# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/programs/Terminal/default.nix（kitty 包）
#     - configuration/home/session.nix（EDITOR/TERMINAL 指向 kitty）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  xdg.configFile = {
    "kitty/kitty.conf".source = ./dotfiles/kitty.conf;
  };
}
