{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device =
          "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4P2NF0M318838M";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "4096M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/rootfs" = { mountpoint = "/"; };
                  "/home" = { mountpoint = "/home"; };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                };
                mountpoint = "/partition-root";
              };
            };
          };
        };
      };
      data = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3YZNB0M524981D";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = { "/data" = { mountpoint = "/data"; }; };
                mountpoint = "/partition-data";
              };
            };
          };
        };
      };
    };
  };
}
