{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.folia-major.packages.${pkgs.stdenv.hostPlatform.system}.default
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
