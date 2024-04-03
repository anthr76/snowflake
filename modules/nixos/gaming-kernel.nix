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
              # FIXME: Depends on https://github.com/ValveSoftware/gamescope/pull/1149
              # extraMakeFlags = [ "KCFLAGS=-DAMD_PRIVATE_COLOR" ];
              ignoreConfigErrors = true;
              suffix = "xanmod1";
              version = "6.8.2";
              modDirVersion = "6.8.2-xanmod1";
              src = pkgs.fetchFromGitHub {
                owner = "xanmod";
                repo = "linux";
                rev = "6.8.2-xanmod1";
                hash = "sha256-JddPg/EWJZq5EIemcaULM5c6yLGkfb2E6shxxq37N3M=";
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
        name = "amd_hdr";
        patch = pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/hhd-dev/linux-handheld/master/6.6/0001-amd-hdr.patch";
          sha256 = "sha256-uoG4/5+Gg8Nw2PdvfUAp4KsZl/pAcz+baixM12eVt9g=";
        };
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
