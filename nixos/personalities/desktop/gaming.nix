{ inputs, pkgs, lib, ... }: {
  # chaotic.mesa-git = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     libva
  #     libvdpau-va-gl
  #     vaapiVdpau
  #     libdrm_git
  #     latencyflex-vulkan
  #     mesa_git
  #     mesa_git.opencl
  #     vulkanPackages_latest.vulkan-loader
  #     vulkanPackages_latest.vulkan-headers
  #     vulkanPackages_latest.vulkan-validation-layers
  #     vulkanPackages_latest.vulkan-extension-layer
  #     vulkanPackages_latest.vulkan-utility-libraries
  #     vulkanPackages_latest.vulkan-volk
  #     vulkanPackages_latest.spirv-headers
  #     vulkanPackages_latest.spirv-tools
  #   ];
  #   extraPackages32 = with pkgs.pkgsi686Linux; [
  #     pkgs.mesa32_git
  #     pkgs.mesa32_git.opencl
  #     libdrm32_git
  #     libva
  #     libvdpau-va-gl
  #     vaapiVdpau
  #   ];
  # };
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
      extraEnv = { STEAM_FORCE_DESKTOPUI_SCALING = "1.5"; };
      extraLibraries = pkgs: [ pkgs.xorg.libxcb ];
    };
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  services.scx.enable = true;
  services.scx.scheduler = "scx_lavd";
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    package = pkgs.gamescope;
  };
  hardware.graphics = {
    enable32Bit = true;
    extraPackages = [ pkgs.gamescope-wsi ];
    extraPackages32 = [ pkgs.pkgsi686Linux.gamescope-wsi ];
  };
  hardware.pulseaudio.support32Bit = true;
  #FIXME: https://github.com/NixOS/nixpkgs/pull/326868
  environment.systemPackages = [ pkgs.vulkan-tools pkgs.amdgpu_top pkgs.gamescope ];
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
  chaotic.hdr.specialisation.enable	= false;
}
