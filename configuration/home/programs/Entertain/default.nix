# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/home/programs/Entertain/cava/default.nix（cava 配置）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.folia-major.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.folia-rust.packages.${system}.default
    go-musicfox
    playerctl
    qq
    cava
    kazumi
    mpv
    google-chrome
    cowsay
    wineWow64Packages.stagingFull
  ];
}
