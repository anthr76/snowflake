{ pkgs, lib, ... }: {
  home.packages = with pkgs; [ any-nix-shell ];
  programs.fish.interactiveShellInit = "any-nix-shell fish --info-right | source";
}
