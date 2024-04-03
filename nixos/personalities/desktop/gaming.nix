{ inputs, pkgs, lib, ... }: {
  # chaotic.mesa-git.enable = true;
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extest.enable = true;
    package = pkgs.steam.override {
      privateTmp = false;
      extraEnv = { STEAM_FORCE_DESKTOPUI_SCALING = "1.5"; };
      extraPkgs = pkgs:
        with pkgs; [
          liberation_ttf
          wqy_zenhei
          # Gamescope
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
          gamemode
        ];
    };
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    package = pkgs.gamescope_git;
  };
  environment.systemPackages = [ pkgs.protontricks pkgs.vulkan-tools pkgs.amdgpu_top ];
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
