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
    ./lsd.nix
  ];
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
  ];
}
