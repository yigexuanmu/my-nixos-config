{
  pkgs,
  ...
}: {
  nixpkgs.overlays = [ (final: prev: {
    inherit (prev.lixPackageSets.latest)
      nixpkgs-review
      nix-direnv
      nix-eval-jobs
      nix-fast-build
      colmena;
  }) ];
  nix.package = pkgs.lixPackageSets.latest.lix;
  nixpkgs.config.allowUnfree = true;
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # 与 WSL 首次安装时的版本一致（官方安装器基线为 26.05，勿随意改动）
  system.stateVersion = "26.05";
}
