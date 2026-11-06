{
  inputs,
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
}
