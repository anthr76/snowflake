{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  programs.hyperland = {
    enable = true;
  };
  qt.enable = true;
  # https://wiki.hyprland.org/Useful-Utilities/Must-have/
  environment.systemPackages = with pkgs; [
    dunst
    lxqt.lxqt-policykit
  ];
}
