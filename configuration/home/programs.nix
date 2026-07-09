{
  inputs,
  ...
}: {
  home.username = "mioha";
  home.homeDirectory = "/home/mioha";

  imports = [
    inputs.lazyvim.homeManagerModules.default
    ./programs/Desktop/default.nix
    ./programs/Desktop/niri
    ./programs/Develop/default.nix
    ./programs/Entertain/default.nix
    ./programs/Entertain/cava
    ./programs/Games/default.nix
    ./programs/Terminal/default.nix
    ./programs/Terminal/fastfetch
    ./programs/Terminal/fish
    ./programs/Terminal/kitty
    ./programs/Utility/default.nix
    ./programs/Utility/obs-studio.nix
  ];

  programs.lazyvim.enable = true;

  programs.git.enable = true;

  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
