{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    extraPackages = [ pkgs.bat-extras.batman ];
    config = {
      theme = "Coldark-Dark";
    };
  };
  home.shellAliases = {
    "cat" = "bat -pp";
    "man" = "batman";
  };
}
