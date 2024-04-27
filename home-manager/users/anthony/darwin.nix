{ pkgs, ... }: {
  imports = [
   ../../personalities/desktop/darwin.nix
  ];
  home = {
    username = "anthony";
    homeDirectory = "/Users/anthony";
  };
  # Yubikey glue usually done only in NixOS.
  # TODO: Check on this for nix-darwin
  home.packages = with pkgs; [ yubico-piv-tool ];
}
