{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device =
          "/dev/disk/by-id/nvme-Sabrent_Rocket_4.0_500GB_03F10711184419353987";
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
                mountOptions = [ "defaults" "umask=0077" ];
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
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_23410U801207";
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
      morpheus = {
        type = "disk";
        device = "/dev/disk/by-id/ata-TOSHIBA_MD09ACA18TR_74A0A004TK2H";
        content = {
          type = "gpt";
          partitions = {
            morpheus = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = { "/morpheus" = { mountpoint = "/morpheus"; }; };
                mountpoint = "/morpheus";
              };
            };
          };
        };
      };
    };
  };
}
