{ config, pkgs, ... }: {
  xdg.desktopEntries = {
    teams = {
      name = "Teams";
      genericName = "Instant Messenger";
      comment = "Microsoft Teams (Google Chrome)";
      exec =
        "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com/";
      terminal = false;
      type = "Application";
    };
  };
}
