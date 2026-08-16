{
  disks ? ["/dev/disk/by-id/nvme-WD_BLACK_SN8100_4000GB_25248A800531"],
  luksCreds,
  # Mapper name for the unlocked volume. Overridden only by disks-migration.nix,
  # which must not reuse `crypted` while the old root still holds that name --
  # disko skips `cryptsetup open` when a mapper of this name already exists, and
  # would then run mkfs on the *running* root. See disks-migration.nix.
  luksName ? "crypted",
  ...
}: {
  # NOTE: do not rename the `primary` disk key. disko derives GPT partition
  # labels as `disk-<key>-<partition>`, and the labels already written to this
  # disk (disk-primary-ESP / -luks / -games) are what initrd and fstab resolve
  # at boot. Renaming the key changes the labels the config expects but not the
  # ones on disk, leaving the system unbootable short of repartitioning.
  #
  # The key was `main` until the 2026-08-15 migration off the Sabrent 2TB. It was
  # renamed so that both drives could be present at once without initrd having
  # two `disk-main-luks` partitions to choose between.
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
              name = luksName;
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
