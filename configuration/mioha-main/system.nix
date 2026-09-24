{
  ...
}: {
  imports = [
    ./packages.nix
    ./device.nix
    ../device/disko.nix
    ../system/boot.nix
    ../system/nix.nix
    ../system/overlays.nix
    ../system/networking.nix
    ../system/user.nix
    ../system/i18n.nix
    ../system/input-method.nix
    ../system/fonts.nix
    ../system/environment.nix
    ../system/tmpfiles.nix
  ];
}
