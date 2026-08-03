{ config, pkgs, ... }: {
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      zfsSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
  boot.supportedFilesystems.zfs = true;
  boot.zfs.package = config.boot.kernelPackages.zfs_cachyos;

  networking.hostId = "1ad3f23c";

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "monthly";
  };

  boot.zfs.extraPools = [ "rpool" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.zfs.requestEncryptionCredentials = false;
  boot.zfs.forceImportRoot = false;
}
