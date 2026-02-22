{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib)
    attrValues
    concatStringsSep
    escapeShellArg
    getExe
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkAfter
    mkIf
    mkOption
    mkOptionDefault
    mkPackageOption
    sort
    types
    ;

  cfg = config.programs.mas;

  apps = mapAttrsToList (name: id: {inherit name id;}) cfg.packages;
  desiredIds = sort builtins.lessThan (map (app: toString app.id) apps);
  homebrewIds = sort builtins.lessThan (map toString (attrValues config.homebrew.masApps));
  hasWork = cfg.update || cfg.packages != {} || cfg.cleanup || homebrewIds != [];

  activationScript =
    if hasWork
    then ''
      echo >&2 "setting up App Store apps (mas)..."

      ${getExe pkgs.bash} <<'MAS_EOF'
      set -euo pipefail

      run_as_user() {
        sudo \
          --preserve-env=PATH \
          --set-home \
          --user=${escapeShellArg cfg.user} \
          "$@"
      }

      list_status=0
      list_output="$(
        run_as_user ${getExe cfg.package} list 2>&1
      )" || list_status=$?

      if [ "$list_status" -ne 0 ]; then
        echo >&2 "warning: mas list failed (exit ''${list_status}):"
        echo >&2 "$list_output"
        if printf '%s' "$list_output" | grep -qi "not signed in"; then
          echo >&2 "login required; skipping App Store installs/updates/cleanup"
          exit 0
        fi
      fi

      installed_ids=()
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        app_id="$(printf '%s' "$line" | awk '{print $1}')"
        [ -n "$app_id" ] && installed_ids+=("$app_id")
      done < <(printf '%s\n' "$list_output")

      desired_ids=(
      ${concatStringsSep "\n" (map (id: "  \"" + id + "\"") desiredIds)}
      )

      homebrew_ids=(
      ${concatStringsSep "\n" (map (id: "  \"" + id + "\"") homebrewIds)}
      )

      if ${if cfg.update then "true" else "false"}; then
        run_as_user ${getExe cfg.package} update || true
      fi

      is_installed() {
        local needle=$1
        local installed_id
        for installed_id in "''${installed_ids[@]}"; do
          if [ "$installed_id" = "$needle" ]; then
            return 0
          fi
        done
        return 1
      }

      for app_id in "''${desired_ids[@]}"; do
        if [ -z "$app_id" ]; then
          continue
        fi
        if is_installed "$app_id"; then
          continue
        fi
        run_as_user ${getExe cfg.package} install "$app_id" || true
      done

      if ${if cfg.cleanup then "true" else "false"}; then
        keep_ids=("''${desired_ids[@]}" "''${homebrew_ids[@]}")

        for installed_id in "''${installed_ids[@]}"; do
          keep=false
          for keep_id in "''${keep_ids[@]}"; do
            if [ "$installed_id" = "$keep_id" ]; then
              keep=true
              break
            fi
          done

          if ! $keep; then
            echo >&2 "removing App Store app id $installed_id"
            run_as_user ${getExe cfg.package} uninstall "$installed_id" || true
          fi
        done
      fi
      MAS_EOF
    ''
    else "";
in {
  options.programs.mas = {
    enable = mkEnableOption "managing Mac App Store apps with mas";

    user = mkOption {
      type = types.str;
      default = config.system.primaryUser;
      defaultText = literalExpression "config.system.primaryUser";
      description = ''
        User account used to run `mas`. This user must be signed in to the Mac App Store.
      '';
    };

    package = mkPackageOption pkgs "mas" {};

    packages = mkOption {
      type = types.attrsOf (types.either types.ints.positive (types.strMatching "^[0-9]+$"));
      default = {};
      example = literalExpression ''
        {
          Xcode = 497799835;
          Tailscale = 1475387142;
        }
      '';
      description = ''
        Apps to install with `mas`. Attribute names are labels; values are numeric app ids.
      '';
    };

    update = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Run `mas update` during activation.
      '';
    };

    cleanup = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Uninstall apps not listed in `programs.mas.packages` or `homebrew.masApps`.
      '';
    };
  };

  config = mkIf cfg.enable {
    system.requiresPrimaryUser =
      mkIf (options.programs.mas.user.highestPrio == (mkOptionDefault {}).priority)
      [
        "programs.mas.enable"
      ];

    environment.systemPackages = [cfg.package];
    system.activationScripts.postActivation.text = mkAfter activationScript;
  };
}
