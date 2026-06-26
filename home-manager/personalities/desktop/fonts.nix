{
  pkgs,
  lib,
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
    emoji = lib.mkIf pkgs.stdenv.isDarwin {
      family = "Apple Color Emoji";
      package = null;
    };
    icon = {
      family = "Symbols Nerd Font Mono";
      package = pkgs.nerd-fonts.symbols-only;
    };
  };
}
