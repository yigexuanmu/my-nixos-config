# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/home/programs/Desktop/default.nix（自动：fuzzel 的配置）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  xdg.configFile = {
    "fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel.ini;
    "fuzzel/scripts/fuzzel-web-search".source = ./dotfiles/scripts/fuzzel-web-search;
  };
}
