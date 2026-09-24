{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.folia-major.packages.${system}.default
    qq
    playerctl
    cava
    kazumi
    mpv
    google-chrome
    cowsay
    wineWow64Packages.stagingFull
  ];
}
