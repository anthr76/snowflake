{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    # Fix: batman is broken
    # extraPackages = [ pkgs.bat-extras.batman ];
    config = {
      theme = "Coldark-Dark";
    };
  };
  home.shellAliases = {
    "cat" = "bat -pp";
  };
}
