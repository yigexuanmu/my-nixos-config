# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/modules/programs/desktop.nix（xdg portal 的 chooser 使用 fuzzel）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  xdg.configFile = {
    "fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel.ini;
    "fuzzel/scripts/fuzzel-web-search".source = ./dotfiles/scripts/fuzzel-web-search;
  };
}
