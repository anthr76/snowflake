{
  disks ? ["/dev/disk/by-id/nvme-WD_BLACK_SN8100_4000GB_25248A800531"],
  luksCreds,
  ...
}: {
  # NOTE: the disk key is `primary` (not `main`) on purpose. disko derives GPT
  # partition labels as `disk-<key>-<partition>`, and the old Sabrent boot disk
  # still carries `disk-main-luks` / `EFI`. Keeping the keys distinct means both
  # drives can be present at once without initrd unlocking the wrong device.
  disk = {
    primary = {
      type = "disk";
      device = builtins.elemAt disks 0;
      content = {
        type = "gpt";
        partitions = {
          # label: disk-primary-ESP
          ESP = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["defaults" "umask=0077"];
            };
          };
          # label: disk-primary-luks
          luks = {
            size = "1100G";
            content = {
              type = "luks";
              name = "crypted";
              extraOpenArgs = ["--allow-discards"];
              settings.keyFile = luksCreds;
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = ["noatime"];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = ["noatime"];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
          # label: disk-primary-games
          # size = "100%" gives this priority 9001 in disko, so it is always
          # created last and absorbs the remaining ~2.5T.
          games = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/games";
              mountOptions = ["defaults" "nofail"];
            };
          };
        };
      };
    };
  };
}
