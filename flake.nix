{
  description = "NixOS WSL configuration (ported from my-nixos-config, WSL-adapted)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lazyvim.url = "github:pfassina/lazyvim-nix";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    # 注意：新版 stylix 已没有 home-manager 这个 input，只跟 nixpkgs
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    miyu.url = "github:yigexuanmu/Miyu";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-wsl,
    ...
  } @ inputs: {
    nixosConfigurations.mioha-wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        inputs.nixos-wsl.nixosModules.default
        inputs.home-manager.nixosModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # HM 接管的文件若已存在（如手写的 starship.toml），自动改名为 *.backup
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.mioha = import ./configuration/mioha-wsl/home.nix;
        }
        ./configuration/mioha-wsl/system.nix
        ./configuration/mioha-wsl/modules.nix
      ];
    };
    # 裸机分体式回归：独立 homeConfigurations，nh home switch 可用
    # 与内嵌的 home-manager.users.mioha 共用同一 home.nix（双模式）
    homeConfigurations.mioha = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs;};
      modules = [./configuration/mioha-wsl/home.nix];
    };
  };
}
