{ config, pkgs, ... }:
let
  gtkConfig = pkgs.writeText "greeter-gtk-config" ''
    window {
      background-color: #282c34;
    }
    box#body {
      background-color: #23272e;
      border: 1;
      border-color: #61afef;
      border-radius: 6px;
      padding: 30px 15px;
    }
  '';

  swayConfig = pkgs.writeText "greeter-sway-config" ''
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -s ${gtkConfig}; swaymsg exit"
    bindsym Mod4+q exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
    exec "dbus-update-activation-environment --systemd --all; systemctl --user import-environment"
  '';
in {
  environment = {
    etc."greetd/environments" = {
      text = ''
        sway
      '';
    };

    systemPackages = with pkgs; [ greetd.gtkgreet ];
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = pkgs.writeShellScript "greeter-sway" ''
          export PATH=${pkgs.sway}/bin:$PATH
          export LD_LIBRARY_PATH=${pkgs.wayland}/lib:${pkgs.libxkbcommon}/lib:$LD_LIBRARY_PATH
          ${pkgs.sway}/bin/sway --config ${swayConfig}
        '';
        user = "greeter";
      };
    };
    vt = 1;
  };
}
