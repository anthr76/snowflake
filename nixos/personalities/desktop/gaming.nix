{inputs, pkgs, lib, ...}:
{
  disabledModules = [
    "${inputs.nixpkgs}/nixos/modules/programs/steam.nix"
  ];
  imports = [
    "${inputs.nixpkgs-pr-299036}/nixos/modules/programs/steam.nix"
  ];
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extest.enable = true;
    package = pkgs.steam.override {
      extraEnv = {
        STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
      };
      extraPkgs = pkgs:
        with pkgs; [
          liberation_ttf
          wqy_zenhei
        ];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  environment.systemPackages = [
    pkgs.vim
    pkgs.vulkan-tools
    pkgs.amdgpu_top
  ];
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "off";
        igpu_desiredgov = "performance";
        igpu_power_threshold = "-1";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = "0";
        amd_performance_level = "high";
      };
    };
  };
  gaming-kernel.enable = true;
}
