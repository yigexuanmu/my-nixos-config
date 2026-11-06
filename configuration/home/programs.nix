{
  inputs,
  pkgs,
  ...
}: {
  home.username = "mioha";
  home.homeDirectory = "/home/mioha";

  imports = [
    inputs.lazyvim.homeManagerModules.default
    ./programs/Desktop/default.nix
    ./programs/Develop/default.nix
    ./programs/Entertain/default.nix
    ./programs/Entertain/cava
    ./programs/Games/default.nix
    ./programs/Terminal/default.nix
    ./programs/Terminal/btop
    ./programs/Terminal/fastfetch
    ./programs/Terminal/fish
    ./programs/Terminal/kitty
    ./programs/Terminal/neovim
    ./programs/Terminal/starship
    ./programs/Terminal/yazi
    ./programs/Utility/default.nix
  ];

  programs.lazyvim.enable = true;

  programs.git.enable = true;

  programs.home-manager.enable = true;

  services.mpris-proxy.enable = true;

  home.stateVersion = "26.05";
}
