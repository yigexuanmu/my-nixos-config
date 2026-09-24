{
  inputs,
  ...
}: {
  imports = [
    inputs.waydroid-nvidia-nix.nixosModules.waydroid-nvidia
  ];

  services.waydroid-nvidia.enable = true;
  services.waydroid-nvidia.refreshRate = 165;
  services.waydroid-nvidia.package = inputs.waydroid-nvidia-nix.packages.x86_64-linux.waydroid-nvidia-full;
}
