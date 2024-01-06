{pkgs, inputs, ...}:
{
  imports = [
    ../../default.nix
    inputs.kde2nix.nixosModules.default
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    wl-clipboard
    plasma5Packages.plasma-thunderbolt
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
