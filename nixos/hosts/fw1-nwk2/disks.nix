{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device =
          "/dev/disk/by-id/ata-BIWIN_SSD_2049061301404";
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
                  "/persist" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/persist";
                  };
                };
                mountpoint = "/partition-root";
              };
            };
          };
        };
      };
    };
  };
}
