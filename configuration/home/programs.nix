{
  inputs,
  ...
}: {
  home.username = "mioha";
  home.homeDirectory = "/home/mioha";

  imports = [
    inputs.lazyvim.homeManagerModules.default
    ./programs/Develop/default.nix
    ./programs/Terminal/default.nix
    ./programs/Terminal/fastfetch
    ./programs/Terminal/fish
  ];

  programs.lazyvim.enable = true;

  programs.git.enable = true;

  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
