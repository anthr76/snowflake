{ disks ? [ "/dev/disk/by-id/nvme-PCIe_SSD_21050610240876" ], luksCreds, ... }: {

    disk = {
      main = {
        type = "disk";
        device = builtins.elemAt disks 0;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "ESP";
              start = "1MiB";
              end = "128MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "crypted";
              start = "128MiB";
              end = "100%";
              content = {
                type = "luks";
                name = "root";
                settings.keyFile = luksCreds;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/rootfs" = {
                      mountpoint = "/";
                    };
                    "/home" = {
                      mountOptions = [ "compress=zstd" ];
                    };
                    "/nix" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            }
          ];
        };
      };
    };
}
