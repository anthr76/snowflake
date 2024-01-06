{pkgs, ...}:
{
  imports = [
    ../../default.nix
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    wl-clipboard
    plasma5Packages.plasma-thunderbolt
  ];
  services = {
    xserver = {
      enable = true;
      desktopManager.plasma5 = {
        enable = true;
      };
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
  };
}
