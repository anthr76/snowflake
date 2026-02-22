{
  lib,
  outputs,
  ...
}: {
  imports = [outputs.darwinModules.mas];

  programs.mas = {
    enable = true;
    update = true;
    cleanup = false;
    packages = {
      "Amphetamine" = "937984704";
      "CARROTweather" = "993487541";
      "Compressor" = "424390742";
      "Final Cut Pro" = "424389933";
      "Flighty" = "1358823008";
      "Gifox" = "1461845568";
      "Home Assistant" = "1099568401";
      "iStat Menus" = "6499559693";
      "Magnet" = "441258766";
      "Mimeo Photos" = "1282504627";
      "Photomator" = "1444636541";
      "Pixelmator Pro" = "1289583905";
      "Telegram" = "747648890";
      "Xnip" = "1221250572";
    };
  };
}
