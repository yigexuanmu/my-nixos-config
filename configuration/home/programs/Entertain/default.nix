{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    splayer
    cava
    kazumi
    mpv
    cowsay
    wineWow64Packages.stagingFull
  ];
}
