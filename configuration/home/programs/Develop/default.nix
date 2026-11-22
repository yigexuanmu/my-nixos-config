# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    ripgrep
    jq
    yq-go
    python314
    uv
    python314Packages.pip
    pipx
    ffmpeg
    websocat
    android-tools
    nix-output-monitor
    hugo
    glow
    strace
    lsof
    vscode
    git
    nh
    pi-coding-agent
    nodejs
    nur.repos.MCSeekeri.workbuddy
    nur.repos.zhyiheihei.zcode
    pandoc
    duckdb
    mediainfo
    typst
    ouch
    zoxide
    glib
    gvfs
  ];
}
