{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "MonaspiceKr Nerd Font Mono";
      package = pkgs.nerdfonts.override { fonts = [ "Monaspace" ]; };
    };
    regular = {
      family = "Roboto";
      package = pkgs.roboto;
    };
  };
}
