{ config, pkgs, ... }: {
  xdg.desktopEntries = {
    teams = {
      name = "Teams";
      genericName = "Instant Messenger";
      comment = "Microsoft Teams (Google Chrome)";
      exec =
        "${pkgs.google-chrome-dev}/bin/google-chrome-unstable --app=https://teams.microsoft.com/";
      terminal = false;
      type = "Application";
    };
  };
}
