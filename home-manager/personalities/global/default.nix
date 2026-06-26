{
  outputs,
  pkgs,
  lib,
  ...
}: {
  imports = [../cli ./sops.nix] ++ (builtins.attrValues outputs.homeManagerModules);
  catppuccin.enable = true;
  catppuccin.autoEnable = false;
  home.activation = {
    diff = lib.hm.dag.entryBefore ["installPackages"] ''
      [[ -z "''${oldGenPath:-}" ]] || [[ "$oldGenPath" = "$newGenPath" ]] || \
         ${pkgs.nvd}/bin/nvd diff "$oldGenPath" "$newGenPath"
    '';
  };
}
