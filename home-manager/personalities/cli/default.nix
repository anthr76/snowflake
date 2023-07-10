{ pkgs, ... }: {
  imports = [
    ./fish.nix
    ./zoxide.nix
    ./editor
    ./git
    ./ssh.nix
  ];
  home.packages = with pkgs; [
    distrobox
    ripgrep
    fd
    jq
  ];
}
