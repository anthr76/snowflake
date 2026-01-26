{
  pkgs,
  lib,
  inputs,
  ...
}: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "Monaspace Neon";
      package = pkgs.monaspace;
    };
    regular = {
      family = "Roboto";
      package = pkgs.roboto;
    };
    emoji = {
      family = "Apple Color Emoji";
      # macOS has Apple Color Emoji built-in, only need the package on Linux
      package =
        if pkgs.stdenv.isLinux
        then inputs.apple-color-emoji.packages.${pkgs.system}.default
        else null;
    };
    icon = {
      family = "Symbols Nerd Font Mono";
      package = pkgs.nerd-fonts.symbols-only;
    };
  };
}
