{ pkgs, ... }:
{
  harmonyos-sans = pkgs.callPackage ./data/fonts/harmonyos-sans.nix { };
  windows-cursor-theme = pkgs.callPackage ./data/cursors/windows-cursor.nix { };
  clash-party = pkgs.callPackage ./tools/networking/clash-party.nix { };
}
