{ pkgs, lib, config, ... }: {
  imports = [ ../../default.nix ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.GTK_USE_PORTAL = "1";
  hardware.sane.enable = true;
  programs.kde-pim.enable = true;
  programs.partition-manager.enable = true;
  programs.dconf.enable = true;
  security.pam.services = {
    login.kwallet.enable = true;
    kde = {
      allowNullPassword = true;
      kwallet.enable = true;
    };
    kde-fingerprint = lib.mkIf config.services.fprintd.enable { fprintAuth = true; };
    kde-smartcard = lib.mkIf config.security.pam.p11.enable { p11Auth = true; };
  };

  hardware.bluetooth.enable = true;
  environment.systemPackages = with pkgs; [
    wl-clipboard
    kdePackages.plasma-thunderbolt
    kdePackages.kcalc
    kdePackages.kdenlive
    ladspaPlugins
    kdePackages.skanlite
    mpv
    xwaylandvideobridge
  ];
  services = {
    xserver = {
      enable = true;
    };
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin";
    };
  };

}
