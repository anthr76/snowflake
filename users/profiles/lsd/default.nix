{ pkgs, lib, ... }: {
  programs.lsd = {
    enable = true;
    enableAliases = true;
  };
}
