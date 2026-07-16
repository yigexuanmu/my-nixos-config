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
    ltrace
    lsof
    vscode
    git
    nh
    opencode
  ];
}
