{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    yazi
    kitty
    btop
    fastfetch
    starship
    eza
    fzf
    tty-clock
    chafa
    inputs.miyu.packages.x86_64-linux.default
  ];
}
