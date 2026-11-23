{
  description = "Mioha’s flake configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";

    lazyvim.url = "github:pfassina/lazyvim-nix";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-mioha.url = "github:yigexuanmu/niri-mioha";

    folia-major = {
      url = "github:yigexuanmu/folia-major";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    folia-rust = {
      url = "github:yigexuanmu/Folia-rust-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    droidloom-nix = {
      url = "github:yigexuanmu/droidloom-nix";
    };

    linuxqq-wayland-fix.url = "github:SHORIN-KIWATA/linuxqq-wayland-fix";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    niri-mioha,
    lazyvim,
    droidloom-nix,
    linuxqq-wayland-fix,
    ...
  } @ inputs: {
    overlays.default = final: prev: import ./configuration/pkgs { pkgs = final; };

    nixosConfigurations.mioha-nix = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        { nixpkgs.overlays = [ self.overlays.default droidloom-nix.overlays.default ]; }

        inputs.disko.nixosModules.disko

      	inputs.nur.modules.nixos.default

        inputs.droidloom-nix.nixosModules.default

        ./configuration/mioha-main/system.nix
        ./configuration/mioha-main/modules.nix

        linuxqq-wayland-fix.nixosModules.default
        {
          nixpkgs.config.allowUnfree = true; # pkgs.qq 是 unfree
          programs.linuxqq-wayland-fix.enable = true;
        }
      ];
    };
    homeConfigurations.mioha = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs;};
      modules = [
      	 inputs.nur.modules.homeManager.default

        ./configuration/mioha-main/home.nix
      ];
    };
  };
}
