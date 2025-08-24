{pkgs, ...}: {
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
    ./bat.nix
    ./direnv.nix
    ./nh.nix
    ./crush.nix
  ];
  home.packages = with pkgs;
    [
      ripgrep
      fd
      jq
      openssl
      cfssl
      sops
      devenv
    ]
    ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      distrobox
    ]);
}
