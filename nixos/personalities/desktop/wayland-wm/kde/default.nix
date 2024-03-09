{pkgs, ...}:
{
  imports = [
    ../../default.nix
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    wl-clipboard
    kdePackages.plasma-thunderbolt
    kdePackages.kcalc
    kdePackages.kdenlive
    vulkan-hdr-layer
  ];
  services = {
    xserver = {
      enable = true;
      desktopManager.plasma6 = {
        enable = true;
      };
      # Currently broken with fish shell
      displayManager.sddm = {
        enable = false;
        wayland.enable = false;
      };
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.greetd}/bin/agreety --cmd startplasma-wayland";
          user = "greeter";
        };
      };
    };
  };
}
