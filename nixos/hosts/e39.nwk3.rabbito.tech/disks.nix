{ disks ? [ "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NX0RA76311 " ], luksCreds, ... }: {

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
              label = "EFI";
              size = "512M";
              type = "EF00" ;
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                    "defaults"
                  ];
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
                      mountPoint = "/home";
                    };
                    "/nix" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/nix";
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
