{
  disko.devices = {
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
                mountpoint = "/boot";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            zfs = {
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
        mode = "";
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posix";
        };
        options.ashift = "12";

        datasets = {
          "ROOT" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "ROOT/default" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.canmount = "noauto";
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
              sync = "standard";
              logbias = "throughput";
              primarycache = "none";
              secondarycache = "none";
            };
          };
        };
      };
    };
  };
}
