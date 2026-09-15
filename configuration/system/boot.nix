{ pkgs, ... }: {
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

  # 根在 LVM LV 上，initramfs 必须先激活 VG，否则挂载失败无法进系统
  boot.initrd.services.lvm.enable = true;

  # 开机必需的挂载点，initramfs 阶段即挂载
  fileSystems."/boot".neededForBoot = true;
  fileSystems."/etc".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/nix/store".neededForBoot = true;

  # btrfs 上需重装后手动执行一次:
  #   sudo btrfs filesystem mkswapfile --size 16G /swap/swapfile
  swapDevices = [{ device = "/swap/swapfile"; }];

  systemd.tmpfiles.rules = [
    "d /var/tmp 1777 root root -"
    "d /var/build 0755 root root -"
  ];
}
