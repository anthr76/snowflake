{pkgs, inputs, ...}: {
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
    ./go.nix
    ./nh.nix
    ./crush.nix
    ./attic.nix
    ./coreutils.nix
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
      inputs.flox.packages.${pkgs.system}.default
    ]
    ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      distrobox
    ]);
}
