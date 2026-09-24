{
  pkgs,
  config,
  lib,
  ... 
}: {
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
  boot.supportedFilesystems.btrfs = true;
  # 禁用透明大页，避免 kcompactd0 高 CPU 占用
  boot.kernelParams = [ "transparent_hugepage=never" ];

  boot.initrd.services.lvm.enable = true;

  fileSystems."/boot".neededForBoot = true;
  fileSystems."/etc".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/nix/store".neededForBoot = true;
}
