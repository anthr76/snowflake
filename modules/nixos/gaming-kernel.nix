# TODO: Make this much more robust if it proves useful.
{ pkgs, inputs, lib, config, ... }: {

  # imports = [ inputs.chaotic.nixosModules.default ];
  options = {
    gaming-kernel = {
      enable = lib.mkEnableOption
        "Kernel With various patches and tweaks for gaming and HDR.";
    };
  };

  config = lib.mkIf config.gaming-kernel.enable {
    boot.kernelPatches = [
      {
        name = "amd_vrr";
        patch = ./amd_vrr.patch;
      }
      {
        name = "cap_sys_nice_bgone";
        patch = ./cap_sys_nice_begone.patch;
      }
    ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
  };
}
