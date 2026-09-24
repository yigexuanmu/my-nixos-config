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

  boot.initrd.services.lvm.enable = true;

  fileSystems."/boot".neededForBoot = true;
  fileSystems."/etc".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/nix/store".neededForBoot = true;
  fileSystems."/gnu".neededForBoot = true;
  fileSystems."/gnu/store".neededForBoot = true;

  #   sudo btrfs filesystem mkswapfile --size 16G /swap/swapfile
  swapDevices = [{ device = "/swap/swapfile"; }];

  systemd.tmpfiles.rules = [
    "d /var/tmp 1777 root root -"
    "d /var/build 0755 root root -"
  ];
}
