# Disko 磁盘布局配置
# 使用 by-id 引用磁盘，确保磁盘更换后仍能正确识别
#
# 当前系统已按此布局分区，此文件供重装时格式化使用。
# 现有系统不受影响，除非你主动运行 disko 命令。
#
# 使用方式（需要 root）：
#   sudo nix run github:nix-community/disko -- --mode disko /etc/nixos/configuration/modules/services/disko.nix
#
# 从 live cd 安装时：
#   sudo nix run github:nix-community/disko -- --mode disko /mnt/etc/nixos/configuration/modules/services/disko.nix
#   sudo nixos-install --flake /mnt/etc/nixos#mioha-nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-HYV512X3_XT__2024092900130";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              device = "/dev/disk/by-id/nvme-HYV512X3_XT__2024092900130-part1";
              size = "5G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };
            root = {
              device = "/dev/disk/by-id/nvme-HYV512X3_XT__2024092900130-part2";
              size = "100% - 16G";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-L" "nixos" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
            swap = {
              device = "/dev/disk/by-id/nvme-HYV512X3_XT__2024092900130-part3";
              size = "16G";
              type = "8200";
              content = {
                type = "swap";
              };
            };
          };
        };
      };
    };
  };
}
