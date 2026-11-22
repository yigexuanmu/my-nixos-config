# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/home/programs/Develop/default.nix（git、nh 在 Home 侧也安装）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    gcc
    nh
    git
    distrobox
    libxkbcommon
  ];
}
