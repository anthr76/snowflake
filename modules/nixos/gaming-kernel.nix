# TODO: Make this much more robust if it proves useful.
{ pkgs, lib, config, ... }: {
  options = {
    gaming-kernel = {
      enable = lib.mkEnableOption
        "Kernel With various patches and tweaks for gaming and HDR.";
    };
  };

  config = lib.mkIf config.gaming-kernel.enable {
    nixpkgs.overlays = [
      (final: prev: {
        linux_xanmod_latest_snowflake = prev.pkgs.linuxPackagesFor
          (prev.pkgs.linux_xanmod_latest.override (old:
            with prev.lib; {
              ignoreConfigErrors = true;
              suffix = "xanmod1";
              version = "6.6.25";
              modDirVersion = "6.6.25-xanmod1";
              src = pkgs.fetchFromGitHub {
                owner = "xanmod";
                repo = "linux";
                rev = "df32b000046c82c315edc9420daa399341b2efb3";
                hash = "sha256-f375jX0BTlccJoeEFDQ2ZaVWQhcnWqcSNYHzGjS2DQo=";
              };
            }));
      })
    ];
    boot.kernelPatches = [
      {
        name = "amd_vrr";
        patch = ./amd_vrr.patch;
      }
      {
        name = "cap_sys_nice_bgone";
        patch = ./cap_sys_nice_begone.patch;
      }
      {
        name = "hdr";
        patch = pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/hhd-dev/linux-handheld/master/6.6/0001-HDR.patch";
          sha256 = "sha256-4Lb31Zx/W8NgwJdBhoyvqgME6AQvW5zYwXkzWGbLP74=";
        };
      }
    ];
    boot.kernelPackages = lib.mkForce pkgs.linux_xanmod_latest_snowflake;

  };
}
