# TODO: Make this much more robust if it proves useful.
{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    gaming-kernel = {
      enable = lib.mkEnableOption "Kernel With various patches and tweaks for gaming and HDR.";
    };
  };

  config = lib.mkIf config.gaming-kernel.enable {
    nixpkgs.overlays = [
      (final: prev: {
        # linuxPackages_xanmod = pkgs.linuxPackagesFor (super.linuxPackages_xanmod.override {
          # extraMakeFlags = ["KCFLAGS=-DAMD_PRIVATE_COLOR"];
        #   ignoreConfigErrors = true;
        #   suffix = "xanmod1";
        #   version = "6.8.1";
          # src = pkgs.fetchFromGitHub {
          #   owner = "xanmod";
          #   repo = "linux";
          #   rev = "${super.version}-${super.suffix}";
          #   hash = "";
          # };
        # });
          linux_xanmod_latest_snowflake = prev.pkgs.linuxPackagesFor (
            prev.pkgs.linux_xanmod_latest.override (old: with prev.lib; {
              extraMakeFlags = ["KCFLAGS=-DAMD_PRIVATE_COLOR"];
              ignoreConfigErrors = true;
              suffix = "xanmod1";
              version = "6.8.1";
              modDirVersion = "6.8.1-xanmod1";
              src = pkgs.fetchFromGitHub {
                owner = "xanmod";
                repo = "linux";
                rev = "6.8.1-xanmod1";
                hash = "sha256-FF/1gijFmYzKk4XoXfwtCQ5eGlwFW2l80O43Y4aSx1g=";
              };
            })
          );
        })
    ];
    boot.kernelPatches = [
      {
        name = "amd_vrr";
        patch = ./amd_vrr.patch;
      }
    ];
    boot.kernelPackages = lib.mkForce pkgs.linux_xanmod_latest_snowflake;

  };
}
