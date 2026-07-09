{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    ripgrep
    jq
    yq-go
    python313
    uv
    python313Packages.pip
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
  ];
}
