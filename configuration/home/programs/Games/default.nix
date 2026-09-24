{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    lutris
    protonplus
    osu-lazer-bin
    prismlauncher
    mangohud
  ];
}
