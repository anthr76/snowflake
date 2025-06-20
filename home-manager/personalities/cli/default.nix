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
    ./bat.nix
    ./direnv.nix
  ];
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    openssl
    cfssl
    sops
    nh
  ] ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
            distrobox
        ]);
}
