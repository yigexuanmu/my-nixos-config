# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/programs/Entertain/default.nix（cava 包）
#     - configuration/home/programs/Desktop/waybar/default.nix（cava 脚本）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  xdg.configFile = {
    "cava/config".source = ./dotfiles/config;
    "cava/themes/noctalia".source = ./dotfiles/themes/noctalia;
  };
}
