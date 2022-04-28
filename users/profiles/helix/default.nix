{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    pkgs.channels.latest.helix
  ];

  # TODO: https://github.com/nix-community/home-manager/issues/2921 
  # programs.helix = {
  #   enable = true;
  # };
}
