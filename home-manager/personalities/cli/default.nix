{ pkgs, ... }: {
  imports = [
    ./fish.nix
    ./zoxide.nix
    ./editor
    ./git
    ./ssh.nix
    ./kubernetes.nix
    ./starship.nix
    ./viddy.nix
    ./lsd.nix
    ./containers.nix
  ];
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    distrobox
    openssl
    cfssl
    sops
  ];
}
