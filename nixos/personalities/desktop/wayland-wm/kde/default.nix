{pkgs, ...}:
{
  imports = [
    ../../default.nix
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  hardware.sane.enable = true;
  environment.systemPackages = with pkgs; [
    wl-clipboard
    kdePackages.plasma-thunderbolt
    kdePackages.kcalc
    kdePackages.kdenlive
    kdePackages.skanlite
    vulkan-hdr-layer
  ];
  services = {
    xserver = {
      enable = true;
      desktopManager.plasma6 = {
        enable = true;
      };
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
  };

}
