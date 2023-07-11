{ inputs, lib, config, pkgs, ... }: {

  imports = [
    ../rofi.nix
    ../sddm.nix
    ../waybar.nix
  ];
  programs.hyprland = {
    enable = true;
  };
  qt.enable = true;
  # https://wiki.hyprland.org/Useful-Utilities/Must-have/
  environment.systemPackages = with pkgs; [
    dunst
    lxqt.lxqt-policykit
    hyprpaper
    xdg-desktop-portal-hyprland
  ];
}
