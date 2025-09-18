{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.home.autoUpgrade;

  timerConfigType = types.submodule ({ ... }: {
    options = {
      onCalendar = mkOption {
        type = types.str;
        default = "Sun *-*-* 03:00:00";
        description = ''systemd `OnCalendar` expression controlling when the upgrade runs.'';
        example = "daily";
      };

      randomizedDelaySec = mkOption {
        type = types.nullOr types.str;
        default = "1800";
        description = "Randomised delay applied to timer starts.";
        example = "30m";
      };

      persistent = mkOption {
        type = types.bool;
        default = true;
        description = "Whether missed runs should be triggered when the system resumes.";
      };

      accuracySec = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional systemd timer accuracy.";
        example = "5min";
      };

      wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ "timers.target" ];
        description = "Targets that want to pull in the timer.";
      };
    };
  });

  escapeArgs = args: concatMapStringsSep " " escapeShellArg args;

in {
  options.services.home.autoUpgrade = {
    enable = mkEnableOption "automatic Home Manager upgrades";

    serviceName = mkOption {
      type = types.str;
      default = "home-auto-upgrade";
      description = "Name of the generated systemd user service/timer.";
    };

    description = mkOption {
      type = types.str;
      default = "Automatic Home Manager upgrade";
      description = "Human-friendly description for the systemd unit.";
    };

    flake = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''Flake reference (e.g. `github:example/repo` or `/path/to/flake`).'';
      example = "github:anthr76/snowflake/stable";
    };

    configuration = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''Optional home configuration attribute appended as `#attr`. Leave as null to let Home Manager infer it.'';
      example = "anthony@generic";
    };

    extraSwitchArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional arguments passed to `home-manager switch`.";
    };

    homeManagerPackage = mkOption {
      type = types.package;
      default = pkgs.home-manager;
      defaultText = literalExpression "pkgs.home-manager";
      description = "Home Manager package providing the `home-manager` CLI.";
    };

    pathPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        bash
        cacert
        coreutils
        curl
        diffutils
        findutils
        git
        gnugrep
        gnused
        gnutar
        gzip
        openssh
        rsync
        xz
        nix
      ];
      description = "Packages exposed on `PATH` while the service runs.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables for the service.";
    };

    requiresNetwork = mkOption {
      type = types.bool;
      default = true;
      description = "Whether the service should wait for network-online.target.";
    };

    preSwitch = mkOption {
      type = types.lines;
      default = "";
      description = "Commands executed immediately before `home-manager switch`.";
      example = ''
        git -C "$HOME/dev/snowflake" pull --ff-only
      '';
    };

    postSwitch = mkOption {
      type = types.lines;
      default = "";
      description = "Commands executed after a successful switch.";
      example = ''
        ${pkgs.nvd}/bin/nvd diff "$oldGenPath" "$newGenPath"
      '';
    };

    timer = mkOption {
      type = timerConfigType;
      default = {};
      description = "Timer configuration for the upgrade service.";
    };

    unitConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra attributes merged into the service's `Unit` section.";
    };

    serviceConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra attributes merged into the service's `Service` section.";
    };

    scriptName = mkOption {
      type = types.str;
      default = "home-auto-upgrade";
      description = "Basename used for the generated switch script.";
    };
  };

  config = mkIf cfg.enable (
    let

      baseFlake = assert cfg.flake != null; cfg.flake;

      flakeRef =
        if cfg.configuration == null then baseFlake
        else "${baseFlake}#${cfg.configuration}";

      pathValue = lib.makeBinPath (cfg.pathPackages ++ [ cfg.homeManagerPackage ]);

      hmBin = "${cfg.homeManagerPackage}/bin/home-manager";

      extraArgs = escapeArgs cfg.extraSwitchArgs;

      upgradeScript = pkgs.writeShellScript "${cfg.scriptName}" ''
        set -euo pipefail
        export PATH=${pathValue}
        ${optionalString cfg.preSwitch != "" cfg.preSwitch}
        ${hmBin} switch --flake ${escapeShellArg flakeRef}${optionalString (extraArgs != "") " ${extraArgs}"}
        ${optionalString cfg.postSwitch != "" cfg.postSwitch}
      '';

      serviceEnv =
        [ "PATH=${pathValue}" ]
        ++ mapAttrsToList (name: value: "${name}=${value}") cfg.environment;

      timerCfg = cfg.timer;
    in {
      assertions = [
        {
          assertion = cfg.flake != null;
          message = "services.home.autoUpgrade.flake must be set when enable = true.";
        }
      ];

      systemd.user.services.${cfg.serviceName} = {
        Unit = mkMerge [
          { Description = cfg.description; }
          (optionalAttrs cfg.requiresNetwork {
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          })
          cfg.unitConfig
        ];

        Service = mkMerge [
          {
            Type = "oneshot";
            Environment = serviceEnv;
            ExecStart = upgradeScript;
          }
          cfg.serviceConfig
        ];
      };

      systemd.user.timers.${cfg.serviceName} = {
        Unit = {
          Description = "${cfg.description} timer";
        };

        Install = {
          WantedBy = timerCfg.wantedBy;
        };

        Timer = mkMerge [
          {
            OnCalendar = timerCfg.onCalendar;
            Persistent = timerCfg.persistent;
          }
          (optionalAttrs (timerCfg.randomizedDelaySec != null) {
            RandomizedDelaySec = timerCfg.randomizedDelaySec;
          })
          (optionalAttrs (timerCfg.accuracySec != null) {
            AccuracySec = timerCfg.accuracySec;
          })
        ];
      };
    }
  );
}
