{inputs, pkgs, lib, ...}:
{
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
        softrealtime = "auto";
      };
      # custom = {
      #   start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
      #   end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      # };
    };
  };
  gaming-kernel.enable = true;
}
