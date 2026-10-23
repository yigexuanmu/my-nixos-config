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

    hyprland.url = "github:hyprwm/Hyprland";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    miyu-agent-nix.url = "github:yigexuanmu/miyu-agent-nix";

    niri-glass.url = "github:yigexuanmu/Niri-glass/beta";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waydroid-nvidia-nix = {
      url = "github:yigexuanmu/waydroid-nvidia-nix/Neo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    folia-major = {
      url = "github:yigexuanmu/folia-major";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    linuxqq-wayland-fix.url = "github:SHORIN-KIWATA/linuxqq-wayland-fix";
    #linuxqq-wayland-fix.url = "github:yigexuanmu/linuxqq-wayland-fix-nix";
  };


  outputs = {
    self,
    nixpkgs,
    home-manager,
    lazyvim,
    niri-glass,
    linuxqq-wayland-fix,
    ...
  } @ inputs: {
    overlays.default = final: prev: import ./configuration/pkgs { pkgs = final; };

    nixosConfigurations.mioha-nix = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        { nixpkgs.overlays = [ self.overlays.default ]; }

        inputs.disko.nixosModules.disko

      	inputs.nur.modules.nixos.default

        ./configuration/mioha-main/system.nix
        ./configuration/mioha-main/modules.nix

        linuxqq-wayland-fix.nixosModules.default
        {
          nixpkgs.config.allowUnfree = true; # pkgs.qq 是 unfree
          programs.linuxqq-wayland-fix.enable = true;
        }
      ];
    };
    homeConfigurations.mioha = let
      # ⚠ 临时 workaround（未来可整块删除）：删除本 let 与下方 in 前改成
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      # 缘由：pyrate-limiter 4.5.0 的 test_factory_leak[create_sqlite_bucket] 在 Python 3.14
      # 下时序不稳（3 次 put 只计到 2 次），305 个用例只此 1 个失败，属上游用例问题。
      # 移除条件：pyrate-limiter 升到已修复该用例的版本，或 nixpkgs 侧已自行 deselect/关检查。
      # 挂载点说明：HM 用 flake 传入的 pkgs，home.nix 里的 nixpkgs.overlays 对它无效，故只能在此。
      # ⚠ 临时 workaround 开始
      pkgs = nixpkgs.legacyPackages.x86_64-linux.extend (final: prev: {
        python3Packages = prev.python3Packages.overrideScope (pyself: pysuper: {
          pyrate-limiter = pysuper.pyrate-limiter.overridePythonAttrs (o: {
            pytestFlags = (o.pytestFlags or []) ++ [
              "--deselect"
              "tests/test_bucket_factory.py::test_factory_leak[create_sqlite_bucket]"
            ];
          });
        });
      });
      # ⚠ 临时 workaround 结束
    in home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit inputs;};
      modules = [
      	 inputs.nur.modules.homeManager.default

        ./configuration/mioha-main/home.nix
      ];
    };
  };
}
