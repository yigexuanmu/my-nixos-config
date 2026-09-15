{
  pkgs,
  ...
}: {
  # vscode 移除：建议 Windows 侧装 VSCode + Remote-WSL，通过 SSH 连本发行版
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
    ltrace
    lsof
    git
    nh
    opencode
  ];
}
