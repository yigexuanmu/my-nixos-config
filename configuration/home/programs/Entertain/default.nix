{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    splayer
    playerctl
    cava
    kazumi
    mpv
    google-chrome
    cowsay
    wineWow64Packages.stagingFull
  ];
}
