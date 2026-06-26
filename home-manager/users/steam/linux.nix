{...}: {
  home = {
    username = "steam";
    homeDirectory = "/home/steam";
  };
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
