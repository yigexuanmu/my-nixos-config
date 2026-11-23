# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  xdg.configFile = {
    "niri/config.kdl".source = ./dotfiles/config.kdl;
    "niri/blur.kdl".source = ./dotfiles/blur.kdl;
    "niri/pop-drop.kdl".source = ./dotfiles/pop-drop.kdl;
    "niri/binds.kdl".source = ./dotfiles/binds.kdl;
  };
}
