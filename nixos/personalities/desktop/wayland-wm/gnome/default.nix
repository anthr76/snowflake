{pkgs, lib, ...}:
{
  imports = [
    ../../default.nix
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  gtk.iconCache.enable = true;
  virtualisation.waydroid.enable = true;
  # TODO: Enable keyring without ssh by overlay
  # https://github.com/NixOS/nixpkgs/issues/166887
  services.gnome.gnome-keyring.enable = lib.mkForce false;
  environment.systemPackages = with pkgs; [
    wl-clipboard
  ];
  services = {
    xserver = {
      enable = true;
      desktopManager.gnome = {
        enable = true;
      };
      displayManager.gdm = {
        enable = true;
        wayland = true;
        autoSuspend = true;
      };
    };
    geoclue2.enable = true;
  };
}
