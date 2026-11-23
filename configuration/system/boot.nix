# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/device/disko.nix（/boot、/etc、/nix 挂载点与 neededForBoot 对应）
#     - configuration/device/hardware/hardware-config.nix（内核模块）
#     - configuration/device/hardware/nvidia.nix（config.boot.kernelPackages 提供 nvidia 驱动）
#     - configuration/system/overlays.nix（cachyos 内核 overlay）
#     - configuration/modules/services/guix.nix（自动：同设 fileSystems.*.neededForBoot）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  config,
  lib,
  ... 
}: {
  boot.loader = {
    limine = {
      enable = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
  boot.supportedFilesystems.btrfs = true;
  # 禁用透明大页，避免 kcompactd0 高 CPU 占用
  # amd_iommu=on / iommu=pt：AMD 平台开 IOMMU，直通设备 DMA 走 identity map
  boot.kernelParams = [
    "transparent_hugepage=never"
    "amd_iommu=on"
    "iommu=pt"
  ];

  # vfio 模块预先可用；不静态绑定任何设备（绑定只发生在 macvm-run.sh 运行期，
  # 内核参数和 initrd 里都不出现 vfio-pci.ids=，否则宿主显卡会被开机抢走）
  boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ];

  # macOS guest 必需：读到未知 MSR 时返回 0，而不是把 guest 杀掉
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1
  '';

  boot.initrd.services.lvm.enable = true;

  fileSystems."/boot".neededForBoot = true;
  fileSystems."/etc".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/nix/store".neededForBoot = true;
}
