{ pkgs, ... }: {
  imports = [ ../../default.nix ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  hardware.sane.enable = true;
  security.pam.services.greetd.kwallet.enable = true;
  hardware.bluetooth.enable = true;
  environment.systemPackages = with pkgs; [
    wl-clipboard
    kdePackages.plasma-thunderbolt
    kdePackages.kcalc
    kdePackages.kdenlive
    kdePackages.skanlite
    xwaylandvideobridge
    vulkan-hdr-layer
  ];
  services = {
    xserver = {
      enable = true;
    };
    desktopManager = {
      plasma6 = {
        enable = true;
        notoPackage = pkgs.noto-fonts-lgc-plus;
      };
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command =
            "${pkgs.greetd.greetd}/bin/agreety --cmd startplasma-wayland";
          user = "greeter";
        };
      };
    };
  };

}
