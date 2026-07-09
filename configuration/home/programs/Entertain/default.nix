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
  ];
}
