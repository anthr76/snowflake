{ pkgs, inputs, ... }: {
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
      package = inputs.apple-color-emoji.packages.${pkgs.system}.default;
    };
    icon = {
      family = "Symbols Nerd Font Mono";
      package = pkgs.nerd-fonts.symbols-only;
    };
  };
}
