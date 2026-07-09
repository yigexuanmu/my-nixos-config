{
  ...
}: {
  imports = [
    ../system/hardware-configuration.nix
    ../system/boot.nix
    ../system/nix.nix
    ../system/networking.nix
    ../system/user.nix
    ../system/i18n.nix
    ../system/fonts/fonts.nix
    ../system/environment.nix
    ../system/desktop.nix
    ../system/programs.nix
    ../system/noctalia.nix
    ../device/hardware/nvidia.nix
  ];
}
