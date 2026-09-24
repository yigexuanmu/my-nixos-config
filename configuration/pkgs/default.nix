{ pkgs, ... }:
{
  harmonyos-sans = pkgs.callPackage ./data/fonts/harmonyos-sans.nix { };
  clash-party = pkgs.callPackage ./tools/networking/clash-party.nix { };
}
