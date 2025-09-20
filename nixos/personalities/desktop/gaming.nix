{
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extest.enable = false;
    protontricks.enable = true;
    fontPackages = with pkgs; [
      liberation_ttf
      wqy_zenhei
      source-han-sans
    ];
    extraPackages = with pkgs; [
      gamemode
    ];
    package = pkgs.steam.override {
      extraEnv = {STEAM_FORCE_DESKTOPUI_SCALING = "1.5";};
      extraLibraries = pkgs: [pkgs.xorg.libxcb];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      proton-cachyos
    ];
  };
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = ["--autopower"];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    package = pkgs.gamescope;
  };
  hardware.graphics = {
    enable32Bit = true;
    extraPackages = [pkgs.gamescope-wsi];
    extraPackages32 = [pkgs.pkgsi686Linux.gamescope-wsi];
  };
  services.pulseaudio.support32Bit = true;
  environment.systemPackages = [pkgs.vulkan-tools pkgs.amdgpu_top pkgs.lsfg-vk-ui pkgs.lsfg-vk];
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
      custom = {
        start = "${pkgs.rpc-bridge}/bin/bridge.sh";
      };
    };
  };
  gaming-kernel.enable = true;
  chaotic.hdr.enable = true;
  chaotic.hdr.specialisation.enable = false;
}
