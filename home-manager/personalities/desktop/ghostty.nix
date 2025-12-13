{
  config,
  pkgs,
  ...
}: {
  catppuccin.ghostty = {
    enable = true;
  };
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin
      then pkgs.ghostty-bin
      else pkgs.ghostty;
    enableFishIntegration = true;
    systemd.enable = pkgs.stdenv.isLinux;
    settings = {
      gtk-titlebar = false;
      font-family = config.fontProfiles.monospace.family;
      font-family-bold = config.fontProfiles.monospace.family;
      font-family-italic = config.fontProfiles.monospace.family;
      font-family-bold-italic = config.fontProfiles.monospace.family;
      font-feature = [
        "zero"
        "calt"
        "liga"
        "clig"
        "ss01"
        "ss02"
        "ss03"
        "ss04"
        "ss05"
        "ss07"
        "ss08"
        "ss09"
        "ss10"
      ];

      shell-integration = "detect";
      shell-integration-features = "ssh-terminfo,ssh-env";

      keybind = [
        "shift+enter=text:\\n"

        "ctrl+h=unbind"
        "ctrl+l=unbind"
      ];
    };
  };
}
