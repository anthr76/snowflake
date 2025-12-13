{
  outputs,
  pkgs,
  lib,
  ...
}: {
  imports = [../cli ./sops.nix] ++ (builtins.attrValues outputs.homeManagerModules);
  home.activation = {
    diff = lib.hm.dag.entryBefore ["installPackages"] ''
      [[ -z "''${oldGenPath:-}" ]] || [[ "$oldGenPath" = "$newGenPath" ]] || \
         ${pkgs.nvd}/bin/nvd diff "$oldGenPath" "$newGenPath"
    '';
  };
}
