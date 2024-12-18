{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "MonaspiceKr Nerd Font Mono";
      package = pkgs.nerd-fonts.monaspace;
    };
    regular = {
      family = "Roboto";
      package = pkgs.roboto;
    };
  };
}
