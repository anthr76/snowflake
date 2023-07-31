{ inputs, lib, config, pkgs, ... }: {

  imports = [
    ../rofi.nix
    ../sddm.nix
    ../waybar.nix
    ../../default.nix
  ];
  programs.hyprland = {
    enable = true;
    package = null;
  };
  # https://wiki.hyprland.org/Useful-Utilities/Must-have/
  environment.systemPackages = with pkgs; [
    dunst
    lxqt.lxqt-policykit
    hyprpaper
    xdg-desktop-portal-hyprland
    # For now
    foot
  ];
}
