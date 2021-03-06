{ pkgs, extraModulesPath, inputs, ... }:
let

  hooks = import ./hooks;

  pkgWithCategory = category: package: { inherit package category; };
  linter = pkgWithCategory "linter";
  docs = pkgWithCategory "docs";
  devos = pkgWithCategory "devos";

in
{
  _file = toString ./.;

  imports = [ "${extraModulesPath}/git/hooks.nix" ];
  git = { inherit hooks; };

  # tempfix: remove when merged https://github.com/numtide/devshell/pull/123
  devshell.startup.load_profiles = pkgs.lib.mkForce (pkgs.lib.noDepEntry ''
    # PATH is devshell's exorbitant privilige:
    # fence against its pollution
    _PATH=''${PATH}
    # Load installed profiles
    for file in "$DEVSHELL_DIR/etc/profile.d/"*.sh; do
      # If that folder doesn't exist, bash loves to return the whole glob
      [[ -f "$file" ]] && source "$file"
    done
    # Exert exorbitant privilige and leave no trace
    export PATH=''${_PATH}
    unset _PATH
  '');

  commands = with pkgs;
    [
      (devos nixUnstable)
      (devos agenix)
      {
        category = "devos";
        name = pkgs.nvfetcher-bin.pname;
        help = pkgs.nvfetcher-bin.meta.description;
        command =
          "cd $PRJ_ROOT/pkgs; ${pkgs.nvfetcher-bin}/bin/nvfetcher -c ./sources.toml $@";
      }
      {
        category = "linter";
        name = "evalnix";
        help = "Check Nix parsing";
        command =
          "fd --extension nix --exec nix-instantiate --parse --quiet {} >/dev/null";
      }
      (linter nixpkgs-fmt)
      (devos fd)
      (linter editorconfig-checker)
      # (docs python3Packages.grip) too many deps
      (docs mdbook)
      (devos inputs.deploy.packages.${pkgs.system}.deploy-rs)
    ] ++ lib.optional (system != "i686-linux") (devos cachix)
    ++ lib.optional (system != "aarch64-darwin")
      (devos inputs.nixos-generators.defaultPackage.${pkgs.system});
}
