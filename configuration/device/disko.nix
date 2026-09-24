# Disko 磁盘布局配置 - Btrfs (pc-mioha)
# 使用 by-id 引用磁盘，确保磁盘更换后仍能正确识别
#
# 分区:
#   ESP  5G vfat -> /efi
#   lvm  100% (PV -> VG vg-mioha)
# LVM:
#   VG vg-mioha -> LV root 100%FREE -> btrfs (label=pc-mioha)
#   扩盘时: 新盘建 PV 加入 vg-mioha, lvextend root, btrfs resize
#
# 挂载:
#   /            -> tmpfs
#   /efi         -> vfat
#   /boot        -> System/@Boot
#   /etc         -> @Config
#   /nix/store   -> System/@Store
#   /home        -> @Home
#   /swap        -> System/@Swap (内含 swapfile, 见下方说明)
#   /nix         -> System/@Nix
#   /var/lib     -> @Data
#   /var/lock    -> tmpfs
#   /var/log     -> System/@Log
#   /var/tmp     -> System/@Tmp
#   /var/build   -> System/@Build
#   /library     -> @Library
#   /sandbox     -> @Sandbox
#   /.snapshots  -> @Snapshot
#
# Swapfile 说明 (btrfs 上 disko 不直接建 swapfile, 重装后手动执行一次):
#   sudo btrfs filesystem mkswapfile --size 16G /swap/swapfile
#   sudo swapon /swap/swapfile
# swapDevices 已在本文件底部声明;
#
# 使用方式（需要 root）：
#   sudo nix run github:nix-community/disko -- --mode disko /etc/nixos/configuration/device/disko.nix
#
# 从 live cd 安装时：
#   sudo nix run github:nix-community/disko -- --mode disko /mnt/etc/nixos/configuration/device/disko.nix
#   sudo nixos-install --flake /mnt/etc/nixos#mioha-nix
{
  disko.devices = {
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=0755"
          "nr_inodes=1m"
          "size=25%"
        ];
      };
      "/var/lock" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=1777"
          "nr_inodes=800k"
          "size=20%"
          "nosuid"
          "nodev"
          "strictatime"
          "X-mount.mkdir"
        ];
      };
    };
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-HYV512X3_XT__2024092900130";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "5G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };
            lvm = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "vg-mioha";
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      vg-mioha = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "pc-mioha" ];
                subvolumes = {
                  "@Config" = {
                    mountpoint = "/etc";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "@Data" = {
                    mountpoint = "/var/lib";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "@Home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "@Library" = {
                    mountpoint = "/library";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "@Sandbox" = {
                    mountpoint = "/sandbox";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "@Snapshot" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Boot" = {
                    mountpoint = "/boot";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Build" = {
                    mountpoint = "/var/build";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Store" = {
                    mountpoint = "/nix/store";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Guix" = {
                    mountpoint = "/gnu";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Guix-Store" = {
                    mountpoint = "/gnu/store";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Swap" = {
                    mountpoint = "/swap";
                    mountOptions = [
                      "nodatacow"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                  "System/@Tmp" = {
                    mountpoint = "/var/tmp";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "X-mount.mkdir"
                    ];
                  };
                };
              };
            };
          };
        };
      };
  };
  #   sudo btrfs filesystem mkswapfile --size 16G /swap/swapfile
  swapDevices = [{ device = "/swap/swapfile"; }];
}
