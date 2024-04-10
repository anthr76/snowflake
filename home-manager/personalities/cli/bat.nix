{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    extraPackages = [ pkgs.bat-extras.batman ];
    theme = "Coldark-Dark";
  };
  home.shellAliases = {
    "cat" = "bat -pp";
    "man" = "batman";
  };
}
