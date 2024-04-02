{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    extraPackages = [ pkgs.bat-extras.batman ];
  };
  home.shellAliases = {
    "cat" = "bat -pp";
    "man" = "batman";
  };
}
