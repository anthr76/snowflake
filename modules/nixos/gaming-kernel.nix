# TODO: Make this much more robust if it proves useful.
{ pkgs, lib, config, ... }: {

  options = {
    gaming-kernel = {
      enable = lib.mkEnableOption
        "Kernel With various patches and tweaks for gaming and HDR.";
    };
  };

  config = lib.mkIf config.gaming-kernel.enable {
    boot.kernelPatches = [
      {
        name = "cap_sys_nice_bgone";
        patch = ./cap_sys_nice_begone.patch;
      }
      {
        name = "blend_tf";
        patch = ./blend_tf.patch;
      }
    ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
    nixpkgs = {
      overlays = [
      (final: prev: {
          gamescope = prev.gamescope.overrideAttrs (oldAttrs: {
            patches = oldAttrs.patches ++ [
              ./0001-allow-gamescope-to-set-ctx-priority.patch
            ];
          });
        })
      ];
    };
  };
}
