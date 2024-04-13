{ config, inputs, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
  ;

  cfg = config.snowflake.steam;
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      warnings = []
        ++ lib.optional (!config.networking.networkmanager.enable)
          "The Steam Deck UI integrates with NetworkManager (networking.networkmanager.enable) which is not enabled. NetworkManager is required to complete the first-time setup process.";
    }
    {
      security.wrappers.gamescope = {
        owner = "root";
        group = "root";
        source = "${pkgs.gamescope_git}/bin/gamescope";
        capabilities = "cap_sys_nice+pie";
      };

      security.wrappers.galileo-mura-extractor = {
        owner = "root";
        group = "root";
        source = "${inputs.jovian-nixos.legacyPackages.${pkgs.system}.galileo-mura}/bin/galileo-mura-extractor";
        setuid = true;
      };
    }
    {
      # Enable MTU probing, as vendor does
      # See: https://github.com/ValveSoftware/SteamOS/issues/1006
      # See also: https://www.reddit.com/r/SteamDeck/comments/ymqvbz/ubisoft_connect_connection_lost_stuck/j36kk4w/?context=3
      boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = true;

      hardware.opengl = {
        driSupport32Bit = true;
        extraPackages = [ pkgs.gamescope-wsi_git ];
        extraPackages32 = [ pkgs.pkgsi686Linux.gamescope-wsi_git ];
      };

      hardware.pulseaudio.support32Bit = true;
      hardware.steam-hardware.enable = mkDefault true;

      environment.systemPackages = [ inputs.jovian-nixos.legacyPackages.${pkgs.system}.gamescope-session inputs.jovian-nixos.legacyPackages.${pkgs.system}.steamos-polkit-helpers ];

      systemd.packages = [ inputs.jovian-nixos.legacyPackages.${pkgs.system}.gamescope-session ];

      services.displayManager.sessionPackages = [ inputs.jovian-nixos.legacyPackages.${pkgs.system}.gamescope-session ];

      # Conflicts with powerbuttond
      services.logind.extraConfig = ''
        HandlePowerKey=ignore
      '';

      services.udev.packages = [
        inputs.jovian-nixos.legacyPackages.${pkgs.system}.powerbuttond
      ];

      # This rule allows the user to configure Wi-Fi in Deck UI.
      #
      # Steam modifies the system network configs via
      # `org.freedesktop.NetworkManager.settings.modify.system`,
      # which normally requires being in the `networkmanager` group.
      security.polkit.extraConfig = ''
        // snowflake-NixOS/steam: Allow users to configure Wi-Fi in Deck UI
        polkit.addRule(function(action, subject) {
          if (
            action.id.indexOf("org.freedesktop.NetworkManager") == 0 &&
            subject.isInGroup("users") &&
            subject.local &&
            subject.active
          ) {
            return polkit.Result.YES;
          }
        });
      '';

      snowflake.steam.environment = {
        # We don't support adopting a drive, yet.
        STEAM_ALLOW_DRIVE_ADOPT = mkDefault "0";
        # Ejecting doesn't work, either.
        STEAM_ALLOW_DRIVE_UNMOUNT = mkDefault "0";
      };
    }
  ]);
}
