{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
    (final: prev: {
      inherit (prev.lixPackageSets.latest)
        nixpkgs-review
        nix-direnv
        nix-eval-jobs
        nix-fast-build
        colmena;
    })
  ];
  nix.package = pkgs.lixPackageSets.latest.lix;
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://attic.xuyh0120.win/lantian"
  ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];
  system.stateVersion = "26.05";
}
