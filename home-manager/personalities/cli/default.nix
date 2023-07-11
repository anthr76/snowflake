{ pkgs, ... }: {
  imports = [
    ./fish.nix
    ./zoxide.nix
    ./editor
    ./git
    ./ssh.nix
    ./kubectl.nix
    ./starship.nix
    ./viddy.nix
  ];
  home.packages = with pkgs; [
    distrobox
    ripgrep
    fd
    jq
  ];
}
