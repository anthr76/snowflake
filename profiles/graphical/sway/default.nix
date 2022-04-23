{ lib, config, options, pkgs, ... }:
let inherit (builtins) readFile;

in {
  programs.sway = {
    enable = true;

    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export NIXOS_OZONE_WL=1
    '';

    extraPackages = with pkgs;
      options.programs.sway.extraPackages.default ++ [
        wofi
        xdg-utils
        gnome.adwaita-icon-theme
        brightnessctl
        mako
        firefox-wayland
        pinentry
        qt5.qtwayland
        alacritty
        wl-clipboard
        grim
        slurp
        waybar
        sway-launcher-desktop
        thunderbird
        element-desktop
        pcmanfm
        super-productivity
	tdesktop
      ];
  };

  environment.etc = {
    "sway/config".text = ''
      ${readFile ./config}
    '';
    "xdg/waybar".source = ./waybar;
  };
  xdg.portal = {
    enable = true;
    #gtkUsePortal = true;
    wlr.enable = true;
  };

  systemd.user.targets.sway-session = {
    enable = true;
    description = "sway compositor session";
    documentation = [ "man:systemd.special(7)" ];

    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    requiredBy = [ "graphical-session.target" "graphical-session-pre.target" ];
  };
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      pkgs.nerdfonts
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.fira
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Code Nerd Font" ];
        serif = [ "Fira Sans" ];
      };
    };
  };

}

