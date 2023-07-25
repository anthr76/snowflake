{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "FiraCode Nerd Font";
      package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
  home.packages = with pkgs; [ fira-code-symbols noto-fonts noto-fonts-emoji ];
}
