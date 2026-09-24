{
  ...
}: {
  imports = [
    ./packages.nix
    ./device.nix
    ../modules/services/disko.nix
    ../system/boot.nix
    ../system/nix.nix
    ../system/networking.nix
    ../system/user.nix
    ../system/i18n.nix
    ../system/fonts.nix
    ../system/environment.nix
    ../system/noctalia.nix
  ];
}
