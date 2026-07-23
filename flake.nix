{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";

    lazyvim.url = "github:pfassina/lazyvim-nix";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";

    daeuniverse.url = "github:daeuniverse/flake.nix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    miyu.url = "github:yigexuanmu/Miyu";

    we-layerd.url = "github:yigexuanmu/we-layerd-nix";

    shorin-niri.url = "github:yigexuanmu/shorin-niri-nix";

    waydroid-nvidia-nix = {
      url = "github:yigexuanmu/waydroid-nvidia-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    lazyvim,
    shorin-niri,
    ...
  } @ inputs: {
    overlays.default = final: prev: import ./configuration/pkgs { pkgs = final; };

    nixosConfigurations.mioha-nix = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        { nixpkgs.overlays = [ self.overlays.default ]; }
        inputs.disko.nixosModules.disko
        inputs.daeuniverse.nixosModules.daed
        ./configuration/mioha-main/system.nix
        ./configuration/mioha-main/modules.nix
      ];
    };
    homeConfigurations.mioha = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs;};
      modules = [./configuration/mioha-main/home.nix];
    };
  };
}
