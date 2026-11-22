# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    viAlias = true;
    vimAlias = true;
  };
}
