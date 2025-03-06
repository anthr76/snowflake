# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ outputs, lib, ... }: {

  imports = [ ../../personalities/desktop/steam.nix ./linux.nix ];
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = lib.mkDefault "23.05";
}
