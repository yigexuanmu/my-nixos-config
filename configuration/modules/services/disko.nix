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
              size = "5G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        mode = "single";
        disk = [ "main" ];
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posix";
          mountpoint = "none";
          canmount = "off";
        };
        options.ashift = "12";

        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "swap" = {
            type = "zfs_volume";
            size = "16G";
            content = {
              type = "swap";
            };
            options = {
              volblocksize = "4K";
            };
          };
        };
      };
    };
  };
}
