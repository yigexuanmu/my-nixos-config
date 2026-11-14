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
