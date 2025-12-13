{
  lib,
  config,
  pkgs,
  ...
}: let
  mkFontOption = kind: {
    family = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "Family name for ${kind} font profile";
      example = "Fira Code";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = "Package for ${kind} font profile";
      example = "pkgs.fira-code";
    };
  };
  cfg = config.fontProfiles;
in {
  options.fontProfiles = {
    enable = lib.mkEnableOption "Whether to enable font profiles";
    monospace = mkFontOption "monospace";
    regular = mkFontOption "regular";
    emoji =
      mkFontOption "emoji"
      // {
        family = lib.mkOption {
          type = lib.types.str;
          default = "Noto Color Emoji";
          description = "Family name for emoji font profile";
          example = "Noto Color Emoji";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.noto-fonts-emoji;
          description = "Package for emoji font profile";
          example = "pkgs.noto-fonts-emoji";
        };
      };
    icon =
      mkFontOption "icon"
      // {
        family = lib.mkOption {
          type = lib.types.str;
          default = "Symbols Nerd Font Mono";
          description = "Family name for icon font profile";
          example = "Symbols Nerd Font Mono";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];};
          description = "Package for icon font profile";
          example = "pkgs.nerdfonts";
        };
      };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    fonts.fontconfig.defaultFonts.emoji = [cfg.emoji.family];
    home.packages = with lib;
      filter (pkg: pkg != null) [
        cfg.monospace.package
        cfg.regular.package
        cfg.emoji.package
        cfg.icon.package
      ];
  };
}
